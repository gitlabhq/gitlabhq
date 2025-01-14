# frozen_string_literal: true

module AppConfig
  class KasMetadata
    attr_reader :enabled, :version, :external_url, :external_k8s_proxy_url

    def self.declarative_policy_class
      "AppConfig::InstanceMetadataPolicy"
    end

    def initialize
      @enabled = Gitlab::Kas.enabled?
      @version = Gitlab::Kas::ServerInfo.new.version_info if @enabled
      @external_url = Gitlab::Kas.external_url if @enabled
      @external_k8s_proxy_url = Gitlab::Kas.tunnel_url if @enabled
    end
  end
end
