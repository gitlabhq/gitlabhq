# frozen_string_literal: true

# Note: initial thinking behind `icon_name` is for it to do triple duty:
# 1. one of our svg icon names, such as `external-link` or a new one `bug`
# 2. if it's an absolute url, then url to a user uploaded icon/image
# 3. an emoji, with the format of `:smile:`
module WorkItems
  class Type < ApplicationRecord
    self.table_name = 'work_item_types'

    include CacheMarkdownField
    include ReactiveCaching

    self.reactive_cache_work_type = :no_dependency
    self.reactive_cache_refresh_interval = 10.minutes
    self.reactive_cache_lifetime = 1.hour

    # type name is used in restrictions DB seeder to assure restrictions for
    # default types are pre-filled
    TYPE_NAMES = {
      issue: 'Issue',
      incident: 'Incident',
      test_case: 'Test Case',
      requirement: 'Requirement',
      task: 'Task',
      objective: 'Objective',
      key_result: 'Key Result',
      epic: 'Epic',
      ticket: 'Ticket'
    }.freeze

    # Base types need to exist on the DB on app startup
    # This constant is used by the DB seeder
    # TODO - where to add new icon names created?
    BASE_TYPES = {
      issue: { name: TYPE_NAMES[:issue], icon_name: 'issue-type-issue', enum_value: 0 },
      incident: { name: TYPE_NAMES[:incident], icon_name: 'issue-type-incident', enum_value: 1 },
      test_case: { name: TYPE_NAMES[:test_case], icon_name: 'issue-type-test-case', enum_value: 2 }, ## EE-only
      requirement: { name: TYPE_NAMES[:requirement], icon_name: 'issue-type-requirements', enum_value: 3 }, ## EE-only
      task: { name: TYPE_NAMES[:task], icon_name: 'issue-type-task', enum_value: 4 },
      objective: { name: TYPE_NAMES[:objective], icon_name: 'issue-type-objective', enum_value: 5 }, ## EE-only
      key_result: { name: TYPE_NAMES[:key_result], icon_name: 'issue-type-keyresult', enum_value: 6 }, ## EE-only
      epic: { name: TYPE_NAMES[:epic], icon_name: 'issue-type-epic', enum_value: 7 }, ## EE-only
      ticket: { name: TYPE_NAMES[:ticket], icon_name: 'issue-type-issue', enum_value: 8 }
    }.freeze

    # A list of types user can change between - both original and new
    # type must be included in this list. This is needed for legacy issues
    # where it's possible to switch between issue and incident.
    CHANGEABLE_BASE_TYPES = %w[issue incident test_case].freeze

    cache_markdown_field :description, pipeline: :single_line

    enum base_type: BASE_TYPES.transform_values { |value| value[:enum_value] }

    belongs_to :namespace, optional: true
    has_many :work_items, class_name: 'Issue', foreign_key: :work_item_type_id, inverse_of: :work_item_type
    has_many :widget_definitions, foreign_key: :work_item_type_id, inverse_of: :work_item_type
    has_many :enabled_widget_definitions, -> { where(disabled: false) }, foreign_key: :work_item_type_id,
      inverse_of: :work_item_type, class_name: 'WorkItems::WidgetDefinition'
    has_many :child_restrictions, class_name: 'WorkItems::HierarchyRestriction', foreign_key: :parent_type_id,
      inverse_of: :parent_type
    has_many :allowed_child_types_by_name, -> { order_by_name_asc },
      through: :child_restrictions, class_name: 'WorkItems::Type',
      foreign_key: :child_type_id, source: :child_type

    before_validation :strip_whitespace
    after_save :clear_reactive_cache!

    # TODO: review validation rules
    # https://gitlab.com/gitlab-org/gitlab/-/issues/336919
    validates :name, presence: true
    validates :name, uniqueness: { case_sensitive: false, scope: [:namespace_id] }
    validates :name, length: { maximum: 255 }
    validates :icon_name, length: { maximum: 255 }

    scope :default, -> { where(namespace: nil) }
    scope :order_by_name_asc, -> { order(arel_table[:name].lower.asc) }
    scope :by_type, ->(base_type) { where(base_type: base_type) }

    def self.default_by_type(type)
      found_type = find_by(namespace_id: nil, base_type: type)
      return found_type if found_type

      Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter.upsert_types
      Gitlab::DatabaseImporters::WorkItems::HierarchyRestrictionsImporter.upsert_restrictions
      Gitlab::DatabaseImporters::WorkItems::RelatedLinksRestrictionsImporter.upsert_restrictions
      find_by(namespace_id: nil, base_type: type)
    end

    def self.default_issue_type
      default_by_type(:issue)
    end

    def self.allowed_types_for_issues
      base_types.keys.excluding('objective', 'key_result', 'epic', 'ticket')
    end

    def default?
      namespace.blank?
    end

    # resource_parent is used in EE
    def widgets(_resource_parent)
      enabled_widget_definitions.filter_map(&:widget_class)
    end

    def supports_assignee?(resource_parent)
      widgets(resource_parent).include?(::WorkItems::Widgets::Assignees)
    end

    def supports_time_tracking?(resource_parent)
      widgets(resource_parent).include?(::WorkItems::Widgets::TimeTracking)
    end

    def default_issue?
      name == WorkItems::Type::TYPE_NAMES[:issue]
    end

    def calculate_reactive_cache
      allowed_child_types_by_name
    end

    def allowed_child_types(cache: false)
      cached_data = cache ? with_reactive_cache { |query_data| query_data } : nil

      cached_data || allowed_child_types_by_name
    end

    private

    def strip_whitespace
      name&.strip!
    end
  end
end

WorkItems::Type.prepend_mod
