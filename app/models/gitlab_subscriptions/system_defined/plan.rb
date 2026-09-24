# frozen_string_literal: true

module GitlabSubscriptions
  module SystemDefined
    class Plan
      include ActiveRecord::FixedItemsModel::Model

      DEFAULT = 'default'

      ALL_PLANS = [DEFAULT].freeze
      DEFAULT_PLANS = [DEFAULT].freeze
      private_constant :ALL_PLANS, :DEFAULT_PLANS

      ITEMS = [
        { id: 1, name: 'default', title: 'Default' },
        { id: 2, name: 'free', title: 'Free' },
        { id: 3, name: 'bronze', title: 'Bronze' },
        { id: 4, name: 'silver', title: 'Silver' },
        { id: 5, name: 'premium', title: 'Premium' },
        { id: 6, name: 'gold', title: 'Gold' },
        { id: 7, name: 'ultimate', title: 'Ultimate' },
        { id: 8, name: 'ultimate_trial', title: 'Ultimate Trial' },
        { id: 9, name: 'premium_trial', title: 'Premium Trial' },
        { id: 10, name: 'ultimate_trial_paid_customer', title: 'Ultimate Trial Paid Customer' },
        { id: 11, name: 'opensource', title: 'Opensource' },
        { id: 12, name: 'early_adopter', title: 'Early Adopter' }
      ].freeze

      attribute :name, :string
      attribute :title, :string

      validates :name, presence: true

      class << self
        def default
          find_by!(name: DEFAULT)
        end

        def all_plans
          ALL_PLANS
        end

        def default_plans
          DEFAULT_PLANS
        end

        def names_for_uids(uids)
          where(id: uids).map(&:name)
        end

        def uids_for_names(names)
          where(name: Array.wrap(names).map(&:to_s)).map(&:id)
        end
      end

      # Cached per request: fixed items are process-wide singletons, so the cache cannot live on
      # the instance. The fallback has no plan_id; saving it needs the uid back-fill in !251875.
      def actual_limits
        ::Gitlab::SafeRequestStore.fetch("system_defined_plan:#{id}:actual_limits") do
          ::PlanLimits.find_by(plan_name_uid: id) || ::PlanLimits.new(plan_name_uid: id)
        end
      end

      def default?
        self.class.default_plans.include?(name)
      end

      def paid?
        false
      end

      def ultimate_or_ultimate_trial_plans?
        false
      end

      # Legacy Plan exposes the enum backing value under this name; keep it so call sites swap one-for-one.
      alias_method :plan_name_uid_before_type_cast, :id
    end
  end
end

GitlabSubscriptions::SystemDefined::Plan.prepend_mod
