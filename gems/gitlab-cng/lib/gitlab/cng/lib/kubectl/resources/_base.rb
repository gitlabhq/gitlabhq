# frozen_string_literal: true

require "json"

module Gitlab
  module Cng
    module Kubectl
      module Resources
        # Base class for implementing kubectl resources.
        #
        # Resource should have method {#json} which returns kubectl resource as json string.
        #
        class Base
          def initialize(resource_name)
            @resource_name = resource_name
          end

          # Kubectl resource json
          #
          # @return [String]
          def json
            raise(NoMethodError)
          end

          # Object comparator
          #
          # @param [Base] other
          # @return [Booelan]
          def ==(other)
            self.class == other.class && json == other.json
          end

          private

          attr_reader :resource_name
        end
      end
    end
  end
end
