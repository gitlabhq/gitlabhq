module EE
  module BasePolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:external_authorization_enabled, scope: :global, score: 0) do
        ::EE::Gitlab::ExternalAuthorization.perform_check?
      end

      rule { external_authorization_enabled & ~admin & ~auditor }.policy do
        prevent :read_cross_project
      end
    end
  end
end
