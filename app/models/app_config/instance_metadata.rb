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
  end
end
