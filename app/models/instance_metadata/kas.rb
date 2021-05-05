# frozen_string_literal: true

class InstanceMetadata::Kas
  attr_reader :enabled, :version, :external_url

  def initialize
    @enabled = Gitlab::Kas.enabled?
    @version = Gitlab::Kas.version if @enabled
    @external_url = Gitlab::Kas.external_url if @enabled
  end

  def self.declarative_policy_class
    "InstanceMetadataPolicy"
  end
end
