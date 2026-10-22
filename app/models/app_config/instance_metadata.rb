# frozen_string_literal: true

module AppConfig
  class InstanceMetadata
    attr_reader :version, :revision, :kas, :enterprise

    def initialize(version: Gitlab::VERSION, revision: Gitlab.revision, enterprise: Gitlab.ee?)
      @version = version
      @revision = revision
      @kas = AppConfig::KasMetadata.new
      @enterprise = enterprise
    end

    def plan
      'free' # GitLab CE edition is always free
    end
  end
end

AppConfig::InstanceMetadata.prepend_mod_with('AppConfig::InstanceMetadata')
