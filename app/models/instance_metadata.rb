# frozen_string_literal: true

class InstanceMetadata
  attr_reader :version, :revision

  def initialize(version: Gitlab::VERSION, revision: Gitlab.revision)
    @version = version
    @revision = revision
  end
end
