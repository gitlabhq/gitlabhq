# frozen_string_literal: true

# Note: initial thinking behind `icon_name` is for it to do triple duty:
# 1. one of our svg icon names, such as `external-link` or a new one `bug`
# 2. if it's an absolute url, then url to a user uploaded icon/image
# 3. an emoji, with the format of `:smile:`
module WorkItems
  class Type < ApplicationRecord
    self.table_name = 'work_item_types'

    include CacheMarkdownField

    # type name is used in restrictions DB seeder to assure restrictions for
    # default types are pre-filled
    TYPE_NAMES = {
      issue: 'Issue',
      incident: 'Incident',
      test_case: 'Test Case',
      requirement: 'Requirement',
      task: 'Task',
      objective: 'Objective',
      key_result: 'Key Result'
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
      key_result: { name: TYPE_NAMES[:key_result], icon_name: 'issue-type-keyresult', enum_value: 6 } ## EE-only
    }.freeze

    # A list of types user can change between - both original and new
    # type must be included in this list. This is needed for legacy issues
    # where it's possible to switch between issue and incident.
    CHANGEABLE_BASE_TYPES = %w[issue incident test_case].freeze

    WI_TYPES_WITH_CREATED_HEADER = %w[issue incident].freeze

    cache_markdown_field :description, pipeline: :single_line

    enum base_type: BASE_TYPES.transform_values { |value| value[:enum_value] }

    belongs_to :namespace, optional: true
    has_many :work_items, class_name: 'Issue', foreign_key: :work_item_type_id, inverse_of: :work_item_type
    has_many :widget_definitions, foreign_key: :work_item_type_id, inverse_of: :work_item_type
    has_many :enabled_widget_definitions, -> { where(disabled: false) }, foreign_key: :work_item_type_id,
      inverse_of: :work_item_type, class_name: 'WorkItems::WidgetDefinition'

    before_validation :strip_whitespace

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
      find_by(namespace_id: nil, base_type: type)
    end

    def self.default_issue_type
      default_by_type(:issue)
    end

    def self.allowed_types_for_issues
      base_types.keys.excluding('task', 'objective', 'key_result')
    end

    def default?
      namespace.blank?
    end

    def widgets
      enabled_widget_definitions.filter_map(&:widget_class)
    end

    def supports_assignee?
      widgets.include? ::WorkItems::Widgets::Assignees
    end

    def default_issue?
      name == WorkItems::Type::TYPE_NAMES[:issue]
    end

    private

    def strip_whitespace
      name&.strip!
    end
  end
end
