module EE
  # Namespace EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Namespace` model
  module Namespace
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    FREE_PLAN = 'free'.freeze

    BRONZE_PLAN = 'bronze'.freeze
    SILVER_PLAN = 'silver'.freeze
    GOLD_PLAN = 'gold'.freeze
    EARLY_ADOPTER_PLAN = 'early_adopter'.freeze

    NAMESPACE_PLANS_TO_LICENSE_PLANS = {
      BRONZE_PLAN        => License::STARTER_PLAN,
      SILVER_PLAN        => License::PREMIUM_PLAN,
      GOLD_PLAN          => License::ULTIMATE_PLAN,
      EARLY_ADOPTER_PLAN => License::EARLY_ADOPTER_PLAN
    }.freeze

    LICENSE_PLANS_TO_NAMESPACE_PLANS = NAMESPACE_PLANS_TO_LICENSE_PLANS.invert.freeze
    PLANS = NAMESPACE_PLANS_TO_LICENSE_PLANS.keys.freeze

    prepended do
      belongs_to :plan

      has_one :namespace_statistics

      scope :with_plan, -> { where.not(plan_id: nil) }

      delegate :shared_runners_minutes, :shared_runners_seconds, :shared_runners_seconds_last_reset,
        to: :namespace_statistics, allow_nil: true

      validate :validate_plan_name
      validate :validate_shared_runner_minutes_support
    end

    module ClassMethods
      def plans_with_feature(feature)
        LICENSE_PLANS_TO_NAMESPACE_PLANS.values_at(*License.plans_with_feature(feature))
      end
    end

    override :move_dir
    def move_dir
      succeeded = super

      if succeeded
        all_projects.each do |project|
          old_path_with_namespace = File.join(full_path_was, project.path)

          ::Geo::RepositoryRenamedEventStore.new(
            project,
            old_path: project.path,
            old_path_with_namespace: old_path_with_namespace
          ).create
        end
      end

      succeeded
    end

    # Checks features (i.e. https://about.gitlab.com/products/) availabily
    # for a given Namespace plan. This method should consider ancestor groups
    # being licensed.
    def feature_available?(feature)
      available_features = strong_memoize(:feature_available) do
        Hash.new do |h, feature|
          h[feature] = load_feature_available(feature)
        end
      end

      available_features[feature]
    end

    def feature_available_in_plan?(feature)
      return true if ::License::ANY_PLAN_FEATURES.include?(feature)

      available_features = strong_memoize(:features_available_in_plan) do
        Hash.new do |h, feature|
          h[feature] = (plans.map(&:name) & self.class.plans_with_feature(feature)).any?
        end
      end

      available_features[feature]
    end

    # The main difference between the "plan" column and this method is that "plan"
    # returns nil / "" when it has no plan. Having no plan means it's a "free" plan.
    #
    def actual_plan
      self.plan || Plan.find_by(name: FREE_PLAN)
    end

    def actual_plan_name
      actual_plan&.name || FREE_PLAN
    end

    def shared_runner_minutes_supported?
      if has_parent?
        !Feature.enabled?(:shared_runner_minutes_on_root_namespace)
      else
        true
      end
    end

    def actual_shared_runners_minutes_limit
      shared_runners_minutes_limit ||
        ::Gitlab::CurrentSettings.shared_runners_minutes
    end

    def shared_runners_minutes_limit_enabled?
      shared_runner_minutes_supported? &&
        shared_runners_enabled? &&
        actual_shared_runners_minutes_limit.nonzero?
    end

    def shared_runners_minutes_used?
      shared_runners_minutes_limit_enabled? &&
        shared_runners_minutes.to_i >= actual_shared_runners_minutes_limit
    end

    def shared_runners_enabled?
      if Feature.enabled?(:shared_runner_minutes_on_root_namespace)
        all_projects.with_shared_runners.any?
      else
        projects.with_shared_runners.any?
      end
    end

    # These helper methods are required to not break the Namespace API.
    def plan=(plan_name)
      if plan_name.is_a?(String)
        @plan_name = plan_name # rubocop:disable Gitlab/ModuleWithInstanceVariables

        super(Plan.find_by(name: @plan_name)) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      else
        super
      end
    end

    # TODO, CI/CD Quotas feature check
    #
    def max_active_pipelines
      actual_plan&.active_pipelines_limit.to_i
    end

    def max_pipeline_size
      actual_plan&.pipeline_size_limit.to_i
    end

    private

    def validate_plan_name
      if @plan_name.present? && PLANS.exclude?(@plan_name) # rubocop:disable Gitlab/ModuleWithInstanceVariables
        errors.add(:plan, 'is not included in the list')
      end
    end

    def validate_shared_runner_minutes_support
      return if shared_runner_minutes_supported?

      if shared_runners_minutes_limit_changed?
        errors.add(:shared_runners_minutes_limit, 'is not supported for this namespace')
      end
    end

    def load_feature_available(feature)
      globally_available = License.feature_available?(feature)

      if ::Gitlab::CurrentSettings.should_check_namespace_plan?
        globally_available && feature_available_in_plan?(feature)
      else
        globally_available
      end
    end

    def plans
      @plans ||=
        if parent_id
          Plan.where(id: self_and_ancestors.with_plan.reorder(nil).select(:plan_id))
        else
          Array(plan)
        end
    end
  end
end
