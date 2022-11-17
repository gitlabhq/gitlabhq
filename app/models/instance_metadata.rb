# frozen_string_literal: true

class InstanceMetadata
  attr_reader :version, :revision, :kas, :enterprise

  def initialize(version: Gitlab::VERSION, revision: Gitlab.revision, enterprise: Gitlab.ee?)
    @version = version
    @revision = revision
    @kas = ::InstanceMetadata::Kas.new
    @enterprise = enterprise
  end
end
