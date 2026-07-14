# frozen_string_literal: true

module GitlabSubscriptions
  module SystemDefined
    class Plan
      include ActiveRecord::FixedItemsModel::Model

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
        def names_for_uids(uids)
          where(id: uids).map(&:name)
        end

        def uids_for_names(names)
          where(name: names).map(&:id)
        end
      end
    end
  end
end
