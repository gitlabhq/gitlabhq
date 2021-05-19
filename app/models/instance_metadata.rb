# frozen_string_literal: true

class InstanceMetadata
  attr_reader :version, :revision, :kas

  def initialize(version: Gitlab::VERSION, revision: Gitlab.revision)
    @version = version
    @revision = revision
    @kas = ::InstanceMetadata::Kas.new
  end
end
