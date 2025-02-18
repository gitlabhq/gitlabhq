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
        has_many :cache_entries,
          class_name: 'VirtualRegistries::Packages::Maven::Cache::Entry',
          inverse_of: :upstream

        ignore_column :encrypted_credentials, remove_with: '17.9', remove_after: '2025-01-23'
        ignore_column :encrypted_credentials_iv, remove_with: '17.9', remove_after: '2025-01-23'

        attr_encrypted_options.merge!(
          mode: :per_attribute_iv,
          key: Settings.attr_encrypted_db_key_base_32,
          algorithm: 'aes-256-gcm',
          marshal: true,
          marshaler: ::Gitlab::Json,
          encode: false,
          encode_iv: false
        )

        attr_encrypted :username
        attr_encrypted :password

        validates :group, top_level_group: true, presence: true
        validates :url, addressable_url: { allow_localhost: false, allow_local_network: false }, presence: true
        validates :username, presence: true, if: :password?
        validates :password, presence: true, if: :username?
        validates :url, :username, :password, length: { maximum: 255 }
        validates :cache_validity_hours, numericality: { greater_than_or_equal_to: 0, only_integer: true }
        validates :encrypted_username_iv, :encrypted_password_iv, uniqueness: true, allow_nil: true

        before_validation :set_cache_validity_hours_for_maven_central, if: :url?, on: :create
        after_validation :reset_credentials, if: -> { persisted? && url_changed? }

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

        def default_cache_entries
          cache_entries.default
        end

        def object_storage_key_for(registry_id:)
          hash = Digest::SHA2.hexdigest(SecureRandom.uuid)
          Gitlab::HashedPath.new(
            'virtual_registries',
            'packages',
            'maven',
            registry_id.to_s,
            'upstream',
            id.to_s,
            'cache',
            'entry',
            hash[0..1],
            hash[2..3],
            hash[4..],
            root_hash: registry_id
          ).to_s
        end

        private

        def reset_credentials
          return if username_changed? && password_changed?

          self.username = nil
          self.password = nil
        end

        def set_cache_validity_hours_for_maven_central
          return unless url.start_with?('https://repo1.maven.org/maven2')

          self.cache_validity_hours = 0
        end
      end
    end
  end
end
