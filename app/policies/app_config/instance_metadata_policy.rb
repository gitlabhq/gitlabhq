# frozen_string_literal: true

module AppConfig
  class InstanceMetadataPolicy < BasePolicy
    delegate { :global }
  end
end
