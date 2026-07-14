# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash'

require_relative 'configs/version'
require_relative 'configs/settings'
require_relative 'configs/options'

module Gitlab
  module Configs
    MissingConfig = Class.new(StandardError)

    @on_mutation_warning = nil

    class << self
      attr_writer :on_mutation_warning

      # Called when a caller tries to mutate an Options object. Default: raise.
      def on_mutation_warning(message, extra = {})
        raise(message) unless @on_mutation_warning

        @on_mutation_warning.call(message, extra)
      end

      def build_options(config)
        ::Gitlab::Configs::Options.build(config)
      end

      def load(source = nil, section = nil, &block)
        ::Gitlab::Configs::Settings.new(source, section).extend(Module.new(&block))
      end
    end
  end
end
