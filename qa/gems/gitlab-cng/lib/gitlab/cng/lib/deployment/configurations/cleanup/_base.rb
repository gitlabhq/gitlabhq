# frozen_string_literal: true

module Gitlab
  module Cng
    module Deployment
      module Configurations
        module Cleanup
          # Base class for deployment cleanup
          #
          # This class should implement a single method #{run} which deletes all the objects that are created
          # in specific configuration classes
          #
          class Base
            include Helpers::Output

            def initialize(namespace)
              @namespace = namespace
            end

            # Run cleanup
            #
            # @return [void]
            def run
              raise(NoMethodError, "run not implemented")
            end

            # Instance of {Kubectl::Client}
            #
            # @return [Kubectl::Client]
            def kubeclient
              @kubeclient ||= Kubectl::Client.new(namespace)
            end

            attr_reader :namespace
          end
        end
      end
    end
  end
end
