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

      with_scope :user
      condition(:auditor, score: 0) { @user&.auditor? }

      with_scope :user
      condition(:support_bot, score: 0) { @user&.support_bot? }

      with_scope :global
      condition(:license_block) { License.block_changes? }
    end
  end
end
