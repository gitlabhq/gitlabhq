# frozen_string_literal: true

class WorkItem < Issue
  include Gitlab::Utils::StrongMemoize

  COMMON_QUICK_ACTIONS_COMMANDS = [
    :title, :reopen, :close, :cc, :tableflip, :shrug, :type, :promote_to, :checkin_reminder,
    :subscribe, :unsubscribe, :confidential, :award, :react, :move, :clone, :copy_metadata,
    :duplicate, :promote_to_incident
  ].freeze

  self.table_name = 'issues'
  self.inheritance_column = :_type_disabled

  strip_attributes! :title

  belongs_to :namespace, inverse_of: :work_items

  has_one :parent_link, class_name: '::WorkItems::ParentLink', foreign_key: :work_item_id
  has_one :work_item_parent, through: :parent_link, class_name: 'WorkItem'
  has_one :dates_source,
    class_name: 'WorkItems::DatesSource',
    foreign_key: 'issue_id',
    inverse_of: :work_item,
    autosave: true
  has_one :weights_source, class_name: 'WorkItems::WeightsSource'

  has_many :child_links, class_name: '::WorkItems::ParentLink', foreign_key: :work_item_parent_id
  has_many :work_item_children, through: :child_links, class_name: 'WorkItem',
    foreign_key: :work_item_id, source: :work_item
  has_many :work_item_children_by_relative_position, ->(work_item) { work_item_children_keyset_order(work_item) },
    through: :child_links, class_name: 'WorkItem',
    foreign_key: :work_item_id, source: :work_item

  scope :inc_relations_for_permission_check, -> {
    includes(:author, ::Gitlab::Issues::TypeAssociationGetter.call, project: :project_feature)
  }

  class << self
    def find_by_namespace_and_iid!(namespace, iid)
      find_by!(namespace: namespace, iid: iid)
    end

    def assignee_association_name
      'issue'
    end

    def test_reports_join_column
      'issues.id'
    end

    def namespace_reference_pattern
      %r{
        (?<!#{Gitlab::PathRegex::PATH_START_CHAR})
        ((?<group_or_project_namespace>#{Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX}))
      }xo
    end

    def reference_pattern
      @reference_pattern ||= %r{
        (?:
          (#{namespace_reference_pattern})?#{Regexp.escape(reference_prefix)} |
          #{Regexp.escape(alternative_reference_prefix)}
        )#{Gitlab::Regex.work_item}
      }x
    end

    def link_reference_pattern
      @link_reference_pattern ||= project_or_group_link_reference_pattern(
        'work_items',
        namespace_reference_pattern,
        Gitlab::Regex.work_item
      )
    end

    def work_item_children_keyset_order_config
      Gitlab::Pagination::Keyset::Order.build(
        [
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'state_id',
            column_expression: WorkItem.arel_table[:state_id],
            order_expression: WorkItem.arel_table[:state_id].asc
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'parent_link_relative_position',
            column_expression: WorkItems::ParentLink.arel_table[:relative_position],
            order_expression: WorkItems::ParentLink.arel_table[:relative_position].asc.nulls_last,
            add_to_projections: true,
            nullable: :nulls_last
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'work_item_id',
            order_expression: WorkItems::ParentLink.arel_table['work_item_id'].asc
          )
        ]
      )
    end

    def work_item_children_keyset_order(_work_item)
      keyset_order = work_item_children_keyset_order_config

      keyset_order.apply_cursor_conditions(joins(:parent_link)).reorder(keyset_order)
    end

    def linked_items_keyset_order
      ::Gitlab::Pagination::Keyset::Order.build(
        [
          ::Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'issue_link_id',
            column_expression: IssueLink.arel_table[:id],
            order_expression: IssueLink.arel_table[:id].desc,
            nullable: :not_nullable
          )
        ])
    end

    override :related_link_class
    def related_link_class
      WorkItems::RelatedWorkItemLink
    end

    def sync_callback_class(association_name)
      ::WorkItems::DataSync::NonWidgets.const_get(association_name.to_s.camelcase, false)
    rescue NameError
      nil
    end

    def non_widgets
      [:related_vulnerabilities, :pending_escalations]
    end
  end

  def create_dates_source_from_current_dates
    create_dates_source(
      due_date: due_date,
      start_date: start_date,
      start_date_is_fixed: due_date.present? || start_date.present?,
      due_date_is_fixed: due_date.present? || start_date.present?,
      start_date_fixed: start_date,
      due_date_fixed: due_date
    )
  end

  def noteable_target_type_name
    'issue'
  end

  # Todo: remove method after target_type cleanup
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/416009
  def todoable_target_type_name
    %w[Issue WorkItem]
  end

  def widgets
    strong_memoize(:widgets) do
      work_item_type.widgets(resource_parent).map do |widget_definition|
        widget_definition.widget_class.new(self, widget_definition: widget_definition)
      end
    end
  end

  # Returns widget object if available
  # type parameter can be a symbol, for example, `:description`.
  def get_widget(type)
    widgets.find do |widget|
      widget.instance_of?(WorkItems::Widgets.const_get(type.to_s.camelize, false))
    end
  rescue NameError
    nil
  end

  def ancestors
    hierarchy.ancestors(hierarchy_order: :asc)
  end

  def descendants
    hierarchy.descendants
  end

  def same_type_base_and_ancestors
    hierarchy(same_type: true).base_and_ancestors(hierarchy_order: :asc)
  end

  def same_type_descendants_depth
    hierarchy(same_type: true).max_descendants_depth.to_i
  end

  def supported_quick_action_commands
    commands_for_widgets = work_item_type.widget_classes(resource_parent).flat_map(&:quick_action_commands).uniq

    COMMON_QUICK_ACTIONS_COMMANDS + commands_for_widgets
  end

  # Widgets have a set of quick action params that they must process.
  # Map them to widget_params so they can be picked up by widget services.
  def transform_quick_action_params(command_params)
    common_params = command_params.dup
    widget_params = {}

    work_item_type.widget_classes(resource_parent)
          .filter { |widget| widget.respond_to?(:quick_action_params) }
          .each do |widget|
            widget.quick_action_params
              .filter { |param_name| common_params.key?(param_name) }
              .each do |param_name|
                widget_params[widget.api_symbol] ||= {}
                param_value = common_params.delete(param_name)

                widget_params[widget.api_symbol].merge!(widget.process_quick_action_param(param_name, param_value))
              end
          end

    { common: common_params, widgets: widget_params }
  end

  def linked_work_items(current_user = nil, authorize: true, preload: nil, link_type: nil)
    return [] if new_record?

    linked_work_items = linked_work_items_query(link_type)
                          .preload(preload)
                          .reorder(self.class.linked_items_keyset_order)
    return linked_work_items unless authorize

    cross_project_filter = ->(work_items) { work_items.where(project: project) }
    Ability.work_items_readable_by_user(
      linked_work_items,
      current_user,
      filters: { read_cross_project: cross_project_filter }
    )
  end

  def linked_items_count
    linked_work_items(authorize: false).size
  end

  def supports_time_tracking?
    work_item_type.supports_time_tracking?(resource_parent)
  end

  def due_date
    dates_source&.due_date || read_attribute(:due_date)
  end

  def start_date
    dates_source&.start_date || read_attribute(:start_date)
  end

  def max_depth_reached?(child_type)
    restriction = ::WorkItems::HierarchyRestriction.find_by_parent_type_id_and_child_type_id(
      work_item_type_id,
      child_type.id
    )
    return false unless restriction&.maximum_depth

    if work_item_type_id == child_type.id
      same_type_base_and_ancestors.count >= restriction.maximum_depth
    else
      hierarchy(different_type_id: child_type.id).base_and_ancestors.count >= restriction.maximum_depth
    end
  end

  private

  override :parent_link_confidentiality
  def parent_link_confidentiality
    if confidential? && work_item_children.public_only.exists?
      errors.add(:base, _('All child items must be confidential in order to turn on confidentiality.'))
    end

    if !confidential? && work_item_parent&.confidential?
      errors.add(:base, _('A non-confidential work item cannot have a confidential parent.'))
    end
  end

  def record_create_action
    super

    Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter.track_work_item_created_action(author: author)
  end

  def hierarchy(options = {})
    type_column_name = :"#{::Gitlab::Issues::TypeAssociationGetter.call}_id"
    base = self.class.where(id: id)
    base = base.where(type_column_name => attributes[type_column_name.to_s]) if options[:same_type]
    base = base.where(type_column_name => options[:different_type_id]) if options[:different_type_id]

    ::Gitlab::WorkItems::WorkItemHierarchy.new(base, options: options)
  end

  override :allowed_work_item_type_change
  def allowed_work_item_type_change
    return unless correct_work_item_type_id_changed?

    child_links = WorkItems::ParentLink.for_parents(id)
    parent_link = ::WorkItems::ParentLink.find_by(work_item: self)

    validate_parent_restrictions(parent_link)
    validate_child_restrictions(child_links)
    validate_depth(parent_link, child_links)
  end

  def validate_parent_restrictions(parent_link)
    return unless parent_link

    parent_link.work_item.work_item_type_id = work_item_type_id

    unless parent_link.valid?
      errors.add(
        :work_item_type_id,
        format(
          _('cannot be changed to %{new_type} when linked to a parent %{parent_type}.'),
          new_type: work_item_type.name.downcase,
          parent_type: parent_link.work_item_parent.work_item_type.name.downcase
        )
      )
    end
  end

  def validate_child_restrictions(child_links)
    return if child_links.empty?

    type_id_column = :"#{::Gitlab::Issues::TypeAssociationGetter.call}_id"

    child_type_ids = child_links.joins(:work_item).select(self.class.arel_table[type_id_column]).distinct
    restrictions = ::WorkItems::HierarchyRestriction.where(
      parent_type_id: work_item_type_id,
      child_type_id: child_type_ids
    )

    # We expect a restriction for every child type
    if restrictions.size < child_type_ids.size
      errors.add(
        :work_item_type_id,
        format(_('cannot be changed to %{new_type} with these child item types.'), new_type: work_item_type.name)
      )
    end
  end

  def validate_depth(parent_link, child_links)
    restriction = ::WorkItems::HierarchyRestriction.find_by_parent_type_id_and_child_type_id(
      work_item_type_id,
      work_item_type_id
    )
    return unless restriction&.maximum_depth

    children_with_new_type = self.class.where(id: child_links.select(:work_item_id))
      .where(correct_work_item_type_id: correct_work_item_type_id)
    max_child_depth = ::Gitlab::WorkItems::WorkItemHierarchy.new(children_with_new_type).max_descendants_depth.to_i

    ancestor_depth =
      if parent_link&.work_item_parent && parent_link.work_item_parent.work_item_type_id == work_item_type_id
        parent_link.work_item_parent.same_type_base_and_ancestors.count
      else
        0
      end

    if max_child_depth + ancestor_depth > restriction.maximum_depth - 1
      errors.add(:work_item_type_id, _('reached maximum depth'))
    end
  end

  def linked_work_items_query(link_type)
    type_condition =
      if link_type == WorkItems::RelatedWorkItemLink::TYPE_RELATES_TO
        " AND issue_links.link_type = #{WorkItems::RelatedWorkItemLink.link_types[link_type]}"
      else
        ""
      end

    linked_issues_select
      .joins("INNER JOIN issue_links ON
         (issue_links.source_id = issues.id AND issue_links.target_id = #{id}#{type_condition})
         OR
         (issue_links.target_id = issues.id AND issue_links.source_id = #{id}#{type_condition})")
  end
end

WorkItem.prepend_mod
