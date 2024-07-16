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
        before_save :write_credentials

        private

        def read_credentials
          self.username, self.password = (credentials || {}).values_at('username', 'password')
        end

        def write_credentials
          self.credentials = (credentials || {}).merge('username' => username, 'password' => password)
        end
      end
    end
  end
end
