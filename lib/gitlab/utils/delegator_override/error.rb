# frozen_string_literal: true

module Gitlab
  module Utils
    module DelegatorOverride
      class Error
        attr_accessor :method_name, :target_class, :target_location, :delegator_class, :delegator_location

        def initialize(method_name, target_class, target_location, delegator_class, delegator_location)
          @method_name = method_name
          @target_class = target_class
          @target_location = target_location
          @delegator_class = delegator_class
          @delegator_location = delegator_location
        end

        def to_s
          "#{delegator_class}##{method_name} is overriding #{target_class}##{method_name}. delegator_location: #{delegator_location} target_location: #{target_location}"
        end
      end
    end
  end
end
