# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module ActiveContext
  def self.configure(...)
    ActiveContext::Config.configure(...)
  end
end
