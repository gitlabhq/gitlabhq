# frozen_string_literal: true

class WorkItem < Issue
  include Gitlab::Utils::StrongMemoize

  COMMON_QUICK_ACTIONS_COMMANDS = [
    :title, :reopen, :close, :cc, :tableflip, :shrug
  ].freeze

  self.table_name = 'issues'
  self.inheritance_column = :_type_disabled

  belongs_to :namespace, inverse_of: :work_items
  has_one :parent_link, class_name: '::WorkItems::ParentLink', foreign_key: :work_item_id
  has_one :work_item_parent, through: :parent_link, class_name: 'WorkItem'

  has_many :child_links, class_name: '::WorkItems::ParentLink', foreign_key: :work_item_parent_id
  has_many :work_item_children, through: :child_links, class_name: 'WorkItem',
                                foreign_key: :work_item_id, source: :work_item
  has_many :work_item_children_by_relative_position, -> { work_item_children_keyset_order },
                                                     through: :child_links, class_name: 'WorkItem',
                                                     foreign_key: :work_item_id, source: :work_item

  scope :inc_relations_for_permission_check, -> { includes(:author, project: :project_feature) }

  delegate :supports_assignee?, to: :work_item_type

  class << self
    def assignee_association_name
      'issue'
    end

    def test_reports_join_column
      'issues.id'
    end

    def work_item_children_keyset_order
      keyset_order = Gitlab::Pagination::Keyset::Order.build([
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: :relative_position,
          column_expression: WorkItems::ParentLink.arel_table[:relative_position],
          order_expression: WorkItems::ParentLink.arel_table[:relative_position].asc.nulls_last,
          nullable: :nulls_last,
          distinct: false
        ),
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: :created_at,
          order_expression: WorkItem.arel_table[:created_at].asc,
          nullable: :not_nullable,
          distinct: false
        )
      ])

      includes(:child_links).order(keyset_order)
    end
  end

  def noteable_target_type_name
    'issue'
  end

  def widgets
    strong_memoize(:widgets) do
      work_item_type.widgets.map do |widget_class|
        widget_class.new(self)
      end
    end
  end

  def ancestors
    hierarchy.ancestors(hierarchy_order: :asc)
  end

  def same_type_base_and_ancestors
    hierarchy(same_type: true).base_and_ancestors(hierarchy_order: :asc)
  end

  def same_type_descendants_depth
    hierarchy(same_type: true).max_descendants_depth.to_i
  end

  def supported_quick_action_commands
    commands_for_widgets = work_item_type.widgets.flat_map(&:quick_action_commands).uniq

    COMMON_QUICK_ACTIONS_COMMANDS + commands_for_widgets
  end

  # Widgets have a set of quick action params that they must process.
  # Map them to widget_params so they can be picked up by widget services.
  def transform_quick_action_params(command_params)
    common_params = command_params.deep_dup
    widget_params = {}

    work_item_type.widgets
          .filter { |widget| widget.respond_to?(:quick_action_params) }
          .each do |widget|
            widget.quick_action_params
              .filter { |param_name| common_params.key?(param_name) }
              .each do |param_name|
                widget_params[widget.api_symbol] ||= {}
                widget_params[widget.api_symbol][param_name] = common_params.delete(param_name)
              end
          end

    { common: common_params, widgets: widget_params }
  end

  private

  override :parent_link_confidentiality
  def parent_link_confidentiality
    if confidential? && work_item_children.public_only.exists?
      errors.add(:base, _('A confidential work item cannot have a parent that already has non-confidential children.'))
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
    base = self.class.where(id: id)
    base = base.where(work_item_type_id: work_item_type_id) if options[:same_type]

    ::Gitlab::WorkItems::WorkItemHierarchy.new(base, options: options)
  end
end

WorkItem.prepend_mod
