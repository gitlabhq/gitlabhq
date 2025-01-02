# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/delegation'
require 'connection_pool'
require 'pg'
require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.setup

module ActiveContext
  def self.configure(...)
    ActiveContext::Config.configure(...)
  end

  def self.config
    ActiveContext::Config.current
  end

  def self.adapter
    ActiveContext::Adapter.current
  end
end
