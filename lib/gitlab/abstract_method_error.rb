# frozen_string_literal: true

module Gitlab
  # Error raised when an abstract method is called that must be implemented by a subclass.
  #
  # This error is specifically for the Template Method pattern where a base class
  # defines methods that subclasses are required to override.
  #
  # Unlike NotImplementedError (which is for platform-specific features) or
  # NoMethodError (which has semantic issues with respond_to?), this error
  # clearly indicates that a subclass must provide an implementation.
  #
  # @example Basic usage with automatic message
  #   class BaseProcessor
  #     def process
  #       raise Gitlab::AbstractMethodError
  #     end
  #   end
  #
  # @example With custom message
  #   class BaseProcessor
  #     def process
  #       raise Gitlab::AbstractMethodError, 'Must return a hash with :status and :result keys'
  #     end
  #   end
  class AbstractMethodError < StandardError # rubocop:disable Gitlab/NamespacedClass -- This is a platform level module/function, not product
    def initialize(message = 'Inheriting class must implement this method')
      super
    end
  end
end
