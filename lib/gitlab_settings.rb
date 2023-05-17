# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash'

require_relative 'gitlab_settings/settings'
require_relative 'gitlab_settings/options'

module GitlabSettings
  MissingSetting = Class.new(StandardError)

  def self.load(source = nil, section = nil, &block)
    ::GitlabSettings::Settings
    .new(source, section)
    .extend(Module.new(&block))
  end
end
