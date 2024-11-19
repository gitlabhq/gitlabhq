# frozen_string_literal: true

# This backports https://github.com/rails/sprockets/pull/759 to Sprockets v3.7.2 to
# fix thread-safety issues with compiling SASS.
#
# This pull request has already been merged in Sprockets v4.2.0, but we
# don't plan on upgrading: https://gitlab.com/gitlab-org/gitlab/-/issues/373997#note_1360248557

require 'sprockets/utils'

unless Gem::Version.new(Sprockets::VERSION) == Gem::Version.new('3.7.2')
  raise 'New version of Sprockets detected. This patch can likely be removed.'
end

# rubocop:disable Style/SoleNestedConditional -- Keep the format consistent with upstream project
module Sprockets
  module Utils
    extend self

    MODULE_INCLUDE_MUTEX = Mutex.new
    private_constant :MODULE_INCLUDE_MUTEX

    # Internal: Inject into target module for the duration of the block.
    #
    # mod - Module
    #
    # Returns result of block.
    def module_include(base, mod)
      MODULE_INCLUDE_MUTEX.synchronize do
        old_methods = {}

        mod.instance_methods.each do |sym|
          old_methods[sym] = base.instance_method(sym) if base.method_defined?(sym)
        end

        unless UNBOUND_METHODS_BIND_TO_ANY_OBJECT
          base.send(:include, mod) unless base < mod
        end

        mod.instance_methods.each do |sym|
          method = mod.instance_method(sym)
          base.send(:define_method, sym, method)
        end

        yield
      ensure
        mod.instance_methods.each do |sym|
          base.send(:undef_method, sym) if base.method_defined?(sym)
        end
        old_methods.each do |sym, method|
          base.send(:define_method, sym, method)
        end
      end
    end
  end
end
# rubocop:enable Style/SoleNestedConditional
