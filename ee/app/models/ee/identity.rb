module EE
  module Identity
    extend ActiveSupport::Concern

    prepended do
      belongs_to :saml_provider

      validates :secondary_extern_uid, allow_blank: true, uniqueness: { scope: uniqueness_scope, case_sensitive: false }

      scope :with_secondary_extern_uid, ->(provider, secondary_extern_uid) do
        iwhere(secondary_extern_uid: normalize_uid(provider, secondary_extern_uid)).with_provider(provider)
      end
    end

    class_methods do
      def uniqueness_scope
        [*super, :saml_provider_id]
      end
    end
  end
end
