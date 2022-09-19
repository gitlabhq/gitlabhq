# frozen_string_literal: true

require_relative '../../tooling/danger/config_files'

module Danger
  class ConfigFiles < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::ConfigFiles
  end
end
