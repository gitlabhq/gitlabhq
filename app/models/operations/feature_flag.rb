# frozen_string_literal: true

module Operations
  class FeatureFlag < ApplicationRecord
    include AfterCommitQueue
    include AtomicInternalId
    include IidRoutes
    include Limitable
    include Referable

    self.table_name = 'operations_feature_flags'
    self.limit_scope = :project
    self.limit_name = 'project_feature_flags'

    belongs_to :project

    has_internal_id :iid, scope: :project

    attribute :active, default: true
    attribute :version, default: :new_version_flag

    # strategies exists only for the second version
    has_many :strategies, class_name: 'Operations::FeatureFlags::Strategy'
    has_many :feature_flag_issues
    has_many :issues, through: :feature_flag_issues, inverse_of: :feature_flags

    validates :project, presence: true
    validates :name,
      presence: true,
      length: 2..63,
      format: {
        with: Gitlab::Regex.feature_flag_regex,
        message: ->(_object, _data) {
          s_("Validation|can contain only lowercase letters, digits, '_' and '-'. Must start with a letter, and cannot end with '-' or '_'")
        }
      }
    validates :name, uniqueness: { scope: :project_id }
    validates :description, allow_blank: true, length: 0..255

    accepts_nested_attributes_for :strategies, allow_destroy: true

    scope :ordered, -> { order(:name) }

    scope :enabled, -> { where(active: true) }
    scope :disabled, -> { where(active: false) }

    scope :new_version_only, -> { where(version: :new_version_flag) }

    enum version: {
      new_version_flag: 2
    }

    class << self
      def preload_relations
        preload(strategies: [:scopes, :user_list])
      end

      def preload_project
        preload(:project)
      end

      def for_unleash_client(project, environment)
        includes(strategies: [:scopes, :user_list])
          .where(project: project)
          .merge(Operations::FeatureFlags::Scope.on_environment(environment))
          .reorder(:id)
          .references(:operations_scopes)
      end

      def reference_prefix
        '[feature_flag:'
      end

      def reference_pattern
        @reference_pattern ||= %r{
          #{Regexp.escape(reference_prefix)}(#{::Project.reference_pattern}\/)?(?<feature_flag>\d+)#{Regexp.escape(reference_postfix)}
        }x
      end

      def link_reference_pattern
        @link_reference_pattern ||= compose_link_reference_pattern('feature_flags', %r{(?<feature_flag>\d+)/edit})
      end

      def reference_postfix
        ']'
      end
    end

    def to_reference(from = nil, full: false)
      project
        .to_reference_base(from, full: full)
        .then { |reference_base| reference_base.present? ? "#{reference_base}/" : nil }
        .then { |reference_base| "#{self.class.reference_prefix}#{reference_base}#{iid}#{self.class.reference_postfix}" }
    end

    def related_issues(current_user, preload:)
      issues = ::Issue
        .select('issues.*, operations_feature_flags_issues.id AS link_id')
        .joins(:feature_flag_issues)
        .where(operations_feature_flags_issues: { feature_flag_id: id })
        .order('operations_feature_flags_issues.id ASC')
        .includes(preload)

      Ability.issues_readable_by_user(issues, current_user)
    end

    def path
      Gitlab::Routing.url_helpers.edit_project_feature_flag_path(project, self)
    end

    def hook_attrs
      {
        id: id,
        name: name,
        description: description,
        active: active
      }
    end
  end
end
