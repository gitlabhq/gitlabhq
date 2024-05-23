# frozen_string_literal: true

module Gitlab
  module Cng
    module Kubectl
      # Wrapper around kubectl client
      #
      class Client
        include Helpers::Shell

        def initialize(namespace)
          @namespace = namespace
        end

        # Create namespace
        #
        # @return [String] command output
        def create_namespace
          execute_shell(["kubectl", "create", "namespace", namespace])
        end

        # Create kubernetes resource
        #
        # @param [Resources::Base] resource
        # @return [String] command output
        def create_resource(resource)
          execute_shell(["kubectl", "apply", "-n", namespace, "-f", "-"], stdin_data: resource.json)
        end

        private

        attr_reader :namespace
      end
    end
  end
end
