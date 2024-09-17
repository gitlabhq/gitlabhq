# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Maven
      class Upstream < ApplicationRecord
        belongs_to :group
        has_one :registry_upstream,
          class_name: 'VirtualRegistries::Packages::Maven::RegistryUpstream',
          inverse_of: :upstream
        has_one :registry, class_name: 'VirtualRegistries::Packages::Maven::Registry', through: :registry_upstream
        has_many :cached_responses,
          class_name: 'VirtualRegistries::Packages::Maven::CachedResponse',
          inverse_of: :upstream

        attr_encrypted :credentials,
          mode: :per_attribute_iv,
          key: Settings.attr_encrypted_db_key_base_32,
          algorithm: 'aes-256-gcm',
          marshal: true,
          marshaler: ::Gitlab::Json,
          encode: false,
          encode_iv: false
        attribute :username, :string, default: nil
        attribute :password, :string, default: nil

        validates :group, top_level_group: true, presence: true
        validates :url, addressable_url: { allow_localhost: false, allow_local_network: false }, presence: true
        validates :username, presence: true, if: :password?
        validates :password, presence: true, if: :username?
        validates :url, :username, :password, length: { maximum: 255 }

        after_initialize :read_credentials
        after_validation :reset_credentials, if: -> { persisted? && url_changed? }
        before_save :write_credentials

        prevent_from_serialization(:username, :password) if respond_to?(:prevent_from_serialization)

        def url_for(path)
          full_url = File.join(url, path)
          Addressable::URI.parse(full_url).to_s
        end

        def headers
          return {} unless username.present? && password.present?

          authorization = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)

          { Authorization: authorization }
        end

        private

        def read_credentials
          self.credentials ||= {}

          # if credentials are blank we might have a username + password from initializer. Don't reset them.
          return if credentials.blank?

          self.username, self.password = (credentials || {}).values_at('username', 'password')
          clear_username_change
          clear_password_change
        end

        def write_credentials
          self.credentials = (credentials || {}).merge('username' => username, 'password' => password)
        end

        def reset_credentials
          return if username_changed? && password_changed?

          self.username = nil
          self.password = nil
          self.credentials = {}
        end
      end
    end
  end
end
