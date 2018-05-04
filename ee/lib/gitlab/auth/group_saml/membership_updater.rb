module Gitlab
  module Auth
    module GroupSaml
      class MembershipUpdater
        attr_reader :user, :saml_provider

        delegate :group, to: :saml_provider

        def initialize(user, saml_provider)
          @user = user
          @saml_provider = saml_provider
        end

        def execute
          return if group.member?(@user)

          group.add_user(@user, default_membership_level)
        end

        private

        def default_membership_level
          :guest
        end
      end
    end
  end
end
