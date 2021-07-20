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

    default_value_for :active, true

    # scopes exists only for the first version
    has_many :scopes, class_name: 'Operations::FeatureFlagScope'
    # strategies exists only for the second version
    has_many :strategies, class_name: 'Operations::FeatureFlags::Strategy'
    has_many :feature_flag_issues
    has_many :issues, through: :feature_flag_issues
    has_one :default_scope, -> { where(environment_scope: '*') }, class_name: 'Operations::FeatureFlagScope'

    validates :project, presence: true
    validates :name,
      presence: true,
      length: 2..63,
      format: {
        with: Gitlab::Regex.feature_flag_regex,
        message: Gitlab::Regex.feature_flag_regex_message
      }
    validates :name, uniqueness: { scope: :project_id }
    validates :description, allow_blank: true, length: 0..255
    validate :first_default_scope, on: :create, if: :has_scopes?
    validate :version_associations

    before_create :build_default_scope, if: -> { legacy_flag? && scopes.none? }

    accepts_nested_attributes_for :scopes, allow_destroy: true
    accepts_nested_attributes_for :strategies, allow_destroy: true

    scope :ordered, -> { order(:name) }

    scope :enabled, -> { where(active: true) }
    scope :disabled, -> { where(active: false) }

    scope :new_version_only, -> { where(version: :new_version_flag)}

    enum version: {
      legacy_flag: 1,
      new_version_flag: 2
    }

    class << self
      def preload_relations
        preload(:scopes, strategies: :scopes)
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
        @link_reference_pattern ||= super("feature_flags", %r{(?<feature_flag>\d+)/edit})
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

    def execute_hooks(current_user)
      run_after_commit do
        feature_flag_data = Gitlab::DataBuilder::FeatureFlag.build(self, current_user)
        project.execute_hooks(feature_flag_data, :feature_flag_hooks)
      end
    end

    def hook_attrs
      {
        id: id,
        name: name,
        description: description,
        active: active
      }
    end

    private

    def version_associations
      if new_version_flag? && scopes.any?
        errors.add(:version_associations, 'version 2 feature flags may not have scopes')
      elsif legacy_flag? && strategies.any?
        errors.add(:version_associations, 'version 1 feature flags may not have strategies')
      end
    end

    def first_default_scope
      unless scopes.first.environment_scope == '*'
        errors.add(:default_scope, 'has to be the first element')
      end
    end

    def build_default_scope
      scopes.build(environment_scope: '*', active: self.active)
    end

    def has_scopes?
      scopes.any?
    end
  end
end
