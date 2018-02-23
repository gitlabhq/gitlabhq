# This module is based on: https://gist.github.com/bcardarella/5735987

module Prependable
  def prepend_features(base)
    if base.instance_variable_defined?(:@_dependencies)
      base.instance_variable_get(:@_dependencies) << self
      false
    else
      return false if base < self

      super
      base.singleton_class.send(:prepend, const_get('ClassMethods')) if const_defined?(:ClassMethods)
      @_dependencies.each { |dep| base.send(:prepend, dep) } # rubocop:disable Gitlab/ModuleWithInstanceVariables
      base.class_eval(&@_included_block) if instance_variable_defined?(:@_included_block) # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end
  end
end

module ActiveSupport
  module Concern
    prepend Prependable

    alias_method :prepended, :included
  end
end
