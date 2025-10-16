# frozen_string_literal: true

class WorkItem < Issue
  include Gitlab::Utils::StrongMemoize
  include Gitlab::InternalEventsTracking
  include Import::HasImportSource

  COMMON_QUICK_ACTIONS_COMMANDS = [
    :title, :reopen, :close, :tableflip, :shrug, :type, :promote_to, :checkin_reminder,
    :subscribe, :unsubscribe, :confidential, :award, :react, :move, :clone, :copy_metadata,
    :duplicate, :promote_to_incident, :board_move, :convert_to_ticket, :zoom, :remove_zoom
  ].freeze

  self.table_name = 'issues'
  self.inheritance_column = :_type_disabled

  strip_attributes! :title

  belongs_to :namespace, inverse_of: :work_items

  has_one :parent_link, class_name: '::WorkItems::ParentLink', foreign_key: :work_item_id
  has_one :work_item_parent, through: :parent_link, class_name: 'WorkItem'
  has_one :weights_source, class_name: 'WorkItems::WeightsSource'

  has_many :child_links, class_name: '::WorkItems::ParentLink', foreign_key: :work_item_parent_id
  has_many :work_item_children, through: :child_links, class_name: 'WorkItem',
    foreign_key: :work_item_id, source: :work_item
  has_many :work_item_children_by_relative_position, ->(work_item) { work_item_children_keyset_order(work_item) },
    through: :child_links, class_name: 'WorkItem',
    foreign_key: :work_item_id, source: :work_item

  scope :inc_relations_for_permission_check, -> {
    includes(
      :author, :work_item_type, { project: [:project_feature, { namespace: :route }, :group] }, { namespace: [:route] }
    )
  }

  scope :within_namespace_hierarchy, ->(namespace) do
    return none if namespace.nil? || namespace.traversal_ids.blank?

    if namespace.traversal_ids.length == 1
      # For root groups
      where("namespace_traversal_ids[1] = ?", namespace.id)
    else
      # For subgroups
      ids = namespace.traversal_ids
      next_ids = ids[0..-2] + [ids[-1] + 1]
      where(namespace_traversal_ids: ids...next_ids)
    end
  end

  scope :within_timeframe, ->(start_date, due_date, with_namespace_cte: false) do
    date_filtered_issue_ids = ::WorkItems::DatesSource
                                .select('issue_id')
                                .where('start_date IS NOT NULL OR due_date IS NOT NULL')
                                .where('start_date IS NULL OR start_date <= ?', due_date)
                                .where('due_date IS NULL OR due_date >= ?', start_date)

    # The namespace_ids CTE from by_parent by timeframe helps with performance when querying across multiple namespaces.
    # see: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181904
    if with_namespace_cte
      date_filtered_issue_ids = date_filtered_issue_ids.where('namespace_id IN (SELECT id FROM namespace_ids)')
    end

    joins("INNER JOIN (#{date_filtered_issue_ids.to_sql}) AS filtered_dates ON issues.id = filtered_dates.issue_id")
  end

  scope :with_enabled_widget_definition, ->(type) do
    joins(work_item_type: :enabled_widget_definitions)
      .merge(::WorkItems::WidgetDefinition.by_enabled_widget_type(type))
  end

  scope :with_group_level_and_project_issues_enabled, ->(include_group_level_items: true, exclude_projects: false) do
    return none if exclude_projects && !include_group_level_items
    # Only group-level work items
    return where(project: nil) if exclude_projects

    # All work_items belonging to groups and projects that have the :issues feature enabled
    scope = left_joins(:project).merge(Project.with_issues_enabled)
    # Exclude epics (project_id: nil) if include_group_level is false
    scope = scope.project_level unless include_group_level_items
    scope
  end

  scope :with_work_item_parent_ids, ->(parent_ids) {
    joins("INNER JOIN work_item_parent_links ON work_item_parent_links.work_item_id = issues.id")
      .where(work_item_parent_links: { work_item_parent_id: parent_ids })
  }

  scope :no_parent, -> {
    where_not_exists(WorkItems::ParentLink.where(
      WorkItems::ParentLink.arel_table[:work_item_id].eq(Issue.arel_table[:id])
    ))
  }

  scope :any_parent, -> {
    where_exists(::WorkItems::ParentLink.where(
      ::WorkItems::ParentLink.arel_table[:work_item_id].eq(Issue.arel_table[:id])
    ))
  }

  scope :not_in_parent_ids, ->(parent_ids) {
    where_not_exists(
      WorkItems::ParentLink.where(
        WorkItems::ParentLink.arel_table[:work_item_id].eq(Issue.arel_table[:id])
                             .and(WorkItems::ParentLink.arel_table[:work_item_parent_id].in(parent_ids))
      )
    )
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

    def alternative_reference_prefix_with_postfix
      '[work_item:'
    end

    def reference_pattern
      prefix_with_postfix = alternative_reference_prefix_with_postfix
      if prefix_with_postfix.empty?
        @reference_pattern ||= %r{
        (?:
          (#{namespace_reference_pattern})?#{Regexp.escape(reference_prefix)} |
          #{Regexp.escape(alternative_reference_prefix_without_postfix)}
        )#{Gitlab::Regex.work_item}
      }x
      else
        %r{
        ((?:
          (#{namespace_reference_pattern})?#{Regexp.escape(reference_prefix)} |
          #{alternative_reference_prefix_without_postfix}
        )#{Gitlab::Regex.work_item}) |
        ((?:
          #{Regexp.escape(prefix_with_postfix)}(#{namespace_reference_pattern}/)?
        )#{Gitlab::Regex.work_item(reference_postfix)})
      }x
      end
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

    def linked_items_for(target_ids, preload: nil, link_type: nil)
      select_query =
        select('issues.*,
                issue_links.id AS issue_link_id,
                issue_links.link_type AS issue_link_type_value,
                issue_links.target_id AS issue_link_source_id,
                issue_links.source_id AS issue_link_target_id,
                issue_links.created_at AS issue_link_created_at,
                issue_links.updated_at AS issue_link_updated_at')

      ordered_linked_items(select_query, ids: target_ids, link_type: link_type, preload: preload)
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
      [:pending_escalations]
    end

    def ordered_linked_items(select_query, ids: [], link_type: nil, preload: nil)
      type_condition =
        if link_type == WorkItems::RelatedWorkItemLink::TYPE_RELATES_TO
          " AND issue_links.link_type = #{WorkItems::RelatedWorkItemLink.link_types[link_type]}"
        else
          ""
        end

      query_ids = sanitize_sql_array(['?', Array.wrap(ids)])

      select_query
        .joins("INNER JOIN issue_links ON
          (issue_links.source_id = issues.id AND issue_links.target_id IN (#{query_ids})#{type_condition})
          OR
          (issue_links.target_id = issues.id AND issue_links.source_id IN (#{query_ids})#{type_condition})")
        .preload(preload)
        .reorder(linked_items_keyset_order)
    end

    def find_on_namespaces(ids:, resource_parent:)
      return none if resource_parent.nil?

      group_namespaces = resource_parent.self_and_descendants.select(:id) if resource_parent.is_a?(Group)

      project_namespaces =
        if resource_parent.is_a?(Project)
          Project.id_in(resource_parent)
        else
          resource_parent.all_projects
        end.select('projects.project_namespace_id as id')

      namespaces = Namespace.from_union(
        [group_namespaces, project_namespaces].compact,
        remove_duplicates: false
      )

      Gitlab::SQL::CTE.new(:work_item_ids_cte, id_in(ids))
        .apply_to(all)
        .in_namespaces_with_cte(namespaces)
        .includes(:work_item_type)
    end
  end

  def create_dates_source_from_current_dates
    create_dates_source(date_source_attributes_from_current_dates)
  end

  def date_source_attributes_from_current_dates
    {
      due_date: due_date,
      start_date: start_date,
      start_date_is_fixed: due_date.present? || start_date.present?,
      due_date_is_fixed: due_date.present? || start_date.present?,
      start_date_fixed: start_date,
      due_date_fixed: due_date
    }
  end

  def noteable_target_type_name
    'issue'
  end

  def custom_notification_target_name
    # This is needed so we match the issue events NotificationSetting::EMAIL_EVENTS
    return 'issue' if work_item_type.issue?

    'work_item'
  end

  # Todo: remove method after target_type cleanup
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/416009
  def todoable_target_type_name
    %w[Issue WorkItem]
  end

  def widgets(except_types: [], only_types: nil)
    raise ArgumentError, 'Only one filter is allowed' if only_types.present? && except_types.present?

    strong_memoize_with(:widgets, only_types, except_types) do
      except_types = Array.wrap(except_types)

      widget_definitions.keys.filter_map do |type|
        next if except_types.include?(type)
        next if only_types&.exclude?(type)

        get_widget(type)
      end
    end
  end

  # Returns widget object if available
  # type parameter can be a symbol, for example, `:description`.
  def get_widget(type)
    strong_memoize_with(type) do
      break unless widget_definitions.key?(type.to_sym)

      widget_definitions[type].build_widget(self)
    end
  end

  def widget_definitions
    work_item_type
      .widgets(resource_parent)
      .index_by(&:widget_type)
      .symbolize_keys
  end
  strong_memoize_attr :widget_definitions

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

    linked_items =
      self.class.ordered_linked_items(linked_issues_select, ids: id, link_type: link_type, preload: preload)

    return linked_items unless authorize

    cross_project_filter = ->(work_items) { work_items.where(project: project) }
    Ability.work_items_readable_by_user(
      linked_items,
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

  def supports_parent?
    return false if work_item_type.issue?

    hierarchy_supports_parent?
  end

  def due_date
    dates_source&.due_date || read_attribute(:due_date)
  end

  def start_date
    dates_source&.start_date || read_attribute(:start_date)
  end

  def max_depth_reached?(child_type)
    restriction = ::WorkItems::SystemDefined::HierarchyRestriction.find_by(
      parent_type_id: work_item_type_id,
      child_type_id: child_type.id
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

    track_internal_event(
      'users_creating_work_items',
      user: author,
      project: project,
      additional_properties: {
        label: work_item_type.base_type
      }
    )
  end

  def hierarchy(options = {})
    base = self.class.where(id: id)
    base = base.where(work_item_type_id: work_item_type_id) if options[:same_type]
    base = base.where(work_item_type_id: options[:different_type_id]) if options[:different_type_id]

    ::Gitlab::WorkItems::WorkItemHierarchy.new(base, options: options)
  end

  override :allowed_work_item_type_change
  def allowed_work_item_type_change
    return unless work_item_type_id_changed?

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

    child_type_ids = child_links.joins(:work_item).distinct.pluck('issues.work_item_type_id') # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- Limited number of work item types
    restrictions = ::WorkItems::SystemDefined::HierarchyRestriction.where(
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
    restriction = ::WorkItems::SystemDefined::HierarchyRestriction.find_by(
      parent_type_id: work_item_type_id,
      child_type_id: work_item_type_id
    )
    return unless restriction&.maximum_depth

    children_with_new_type = self.class.where(id: child_links.select(:work_item_id))
      .where(work_item_type_id: work_item_type_id)
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

  def hierarchy_supports_parent?
    ::WorkItems::SystemDefined::HierarchyRestriction.find_by(child_type_id: work_item_type_id).present?
  end
end

WorkItem.prepend_mod
