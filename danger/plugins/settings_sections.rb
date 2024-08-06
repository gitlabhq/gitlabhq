# frozen_string_literal: true

require_relative '../../tooling/danger/settings_sections'

module Danger
  class SettingsSections < ::Danger::Plugin
    include Tooling::Danger::SettingsSections
  end
end
