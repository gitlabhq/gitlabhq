module EE
  # Namespace EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Namespace` model
  module Namespace
    extend ActiveSupport::Concern

    FREE_PLAN = 'free'.freeze

    BRONZE_PLAN = 'bronze'.freeze
    SILVER_PLAN = 'silver'.freeze
    GOLD_PLAN = 'gold'.freeze
    EARLY_ADOPTER_PLAN = 'early_adopter'.freeze

    EE_PLANS = {
      BRONZE_PLAN        => License::STARTER_PLAN,
      SILVER_PLAN        => License::PREMIUM_PLAN,
      GOLD_PLAN          => License::ULTIMATE_PLAN,
      EARLY_ADOPTER_PLAN => License::EARLY_ADOPTER_PLAN
    }.freeze

    prepended do
      belongs_to :plan

      has_one :namespace_statistics

      scope :with_plan, -> { where.not(plan_id: nil) }

      delegate :shared_runners_minutes, :shared_runners_seconds, :shared_runners_seconds_last_reset,
        to: :namespace_statistics, allow_nil: true

      validate :validate_plan_name
    end

    def root_ancestor
      ancestors.reorder(nil).find_by(parent_id: nil)
    end

    def move_dir
      raise NotImplementedError unless defined?(super)

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
      @feature_available ||= Hash.new do |h, feature|
        h[feature] = load_feature_available(feature)
      end

      @feature_available[feature]
    end

    def feature_available_in_plan?(feature)
      @features_available_in_plan ||= Hash.new do |h, feature|
        h[feature] = plans.any? { |plan| License.plan_includes_feature?(EE_PLANS[plan&.name], feature) }
      end

      @features_available_in_plan[feature]
    end

    # The main difference between the "plan" column and this method is that "plan"
    # returns nil / "" when it has no plan. Having no plan means it's a "free" plan.
    def actual_plan
      plan&.name || FREE_PLAN
    end

    def actual_shared_runners_minutes_limit
      shared_runners_minutes_limit ||
        current_application_settings.shared_runners_minutes
    end

    def shared_runners_minutes_limit_enabled?
      shared_runners_enabled? &&
        actual_shared_runners_minutes_limit.nonzero?
    end

    def shared_runners_minutes_used?
      shared_runners_minutes_limit_enabled? &&
        shared_runners_minutes.to_i >= actual_shared_runners_minutes_limit
    end

    # These helper methods are required to not break the Namespace API.
    def plan=(plan_name)
      if plan_name.is_a?(String)
        @plan_name = plan_name

        super(Plan.find_by(name: @plan_name))
      else
        super
      end
    end

    private

    def validate_plan_name
      if @plan_name.present? && EE_PLANS.keys.exclude?(@plan_name)
        errors.add(:plan, 'is not included in the list')
      end
    end

    def load_feature_available(feature)
      globally_available = License.feature_available?(feature)

      if current_application_settings.should_check_namespace_plan?
        globally_available && feature_available_in_plan?(feature)
      else
        globally_available
      end
    end

    def plans
      @ancestors_plans ||=
        if parent_id
          Plan.where(id: ancestors.with_plan.reorder(nil).select('plan_id')) + [plan]
        else
          [plan]
        end
    end
  end
end
