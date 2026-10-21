# frozen_string_literal: true

module Import
  class UserCredential < ApplicationRecord
    TOKEN_MAX_LENGTH = 510

    self.table_name = 'import_user_credentials'

    belongs_to :user, optional: false

    enum :provider, { github: 0 }

    encrypts :access_token
    encrypts :refresh_token

    prevent_from_serialization :access_token, :refresh_token

    normalizes :provider_host, with: ->(host) { host.downcase }

    validates :provider, :provider_host, :provider_account_xid, presence: true
    validates :access_token, presence: true, length: { maximum: TOKEN_MAX_LENGTH }
    validates :refresh_token, length: { maximum: TOKEN_MAX_LENGTH }
    validates :provider_host, :scopes, length: { maximum: 255 }

    scope :for_account, ->(user:, provider:, provider_host:, provider_account_xid:) do
      where(user: user, provider: provider, provider_host: provider_host, provider_account_xid: provider_account_xid)
    end

    def self.store!(user:, provider:, provider_host:, provider_account_xid:, **token_attributes)
      account = {
        user: user, provider: provider, provider_host: provider_host, provider_account_xid: provider_account_xid
      }
      retried = false

      begin
        credential = find_or_initialize_by(account)
        credential.update!(token_attributes)
        credential
      rescue ActiveRecord::RecordNotUnique
        raise if retried

        retried = true
        retry
      end
    end
  end
end
