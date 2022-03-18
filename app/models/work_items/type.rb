# frozen_string_literal: true

# Note: initial thinking behind `icon_name` is for it to do triple duty:
# 1. one of our svg icon names, such as `external-link` or a new one `bug`
# 2. if it's an absolute url, then url to a user uploaded icon/image
# 3. an emoji, with the format of `:smile:`
module WorkItems
  class Type < ApplicationRecord
    self.table_name = 'work_item_types'

    include CacheMarkdownField

    # Base types need to exist on the DB on app startup
    # This constant is used by the DB seeder
    BASE_TYPES = {
      issue:       { name: 'Issue', icon_name: 'issue-type-issue', enum_value: 0 },
      incident:    { name: 'Incident', icon_name: 'issue-type-incident', enum_value: 1 },
      test_case:   { name: 'Test Case', icon_name: 'issue-type-test-case', enum_value: 2 }, ## EE-only
      requirement: { name: 'Requirement', icon_name: 'issue-type-requirements', enum_value: 3 }, ## EE-only
      task:        { name: 'Task', icon_name: 'issue-type-task', enum_value: 4 }
    }.freeze

    cache_markdown_field :description, pipeline: :single_line

    enum base_type: BASE_TYPES.transform_values { |value| value[:enum_value] }

    belongs_to :namespace, optional: true
    has_many :work_items, class_name: 'Issue', foreign_key: :work_item_type_id, inverse_of: :work_item_type

    before_validation :strip_whitespace

    # TODO: review validation rules
    # https://gitlab.com/gitlab-org/gitlab/-/issues/336919
    validates :name, presence: true
    validates :name, uniqueness: { case_sensitive: false, scope: [:namespace_id] }
    validates :name, length: { maximum: 255 }
    validates :icon_name, length: { maximum: 255 }

    scope :default, -> { where(namespace: nil) }
    scope :order_by_name_asc, -> { order('LOWER(name)') }
    scope :by_type, ->(base_type) { where(base_type: base_type) }

    def self.default_by_type(type)
      find_by(namespace_id: nil, base_type: type)
    end

    def self.default_issue_type
      default_by_type(:issue)
    end

    def self.allowed_types_for_issues
      base_types.keys.excluding('task')
    end

    def default?
      namespace.blank?
    end

    private

    def strip_whitespace
      name&.strip!
    end
  end
end
