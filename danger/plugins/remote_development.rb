# frozen_string_literal: true

require_relative '../../tooling/danger/remote_development/desired_config_generator_suggestor'

module Danger
  class RemoteDevelopment < ::Danger::Plugin
    include Tooling::Danger::RemoteDevelopment::DesiredConfigGeneratorSuggestor
  end
end
