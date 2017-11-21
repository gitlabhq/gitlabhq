module EE
  module Identity
    extend ActiveSupport::Concern

    prepended do
      validates :secondary_extern_uid, allow_blank: true, uniqueness: { scope: :provider, case_sensitive: false }

      scope :with_secondary_extern_uid, ->(provider, secondary_extern_uid) do
        iwhere(secondary_extern_uid: normalize_uid(provider, secondary_extern_uid)).with_provider(provider)
      end
    end
  end
end
