# frozen_string_literal: true

module Gitlab
  module Cng
    module Deployment
      module Configurations
        # Base class for creating new deployment configuration
        #
        # Class should implement following methods:
        #
        # * {#run_pre_deployment_setup}
        # * {#run_post_deployment_setup}
        #
        # To skip running pre/post deployment hooks, add calls to {#skip_pre_deployment_setup!} or
        # {#skip_post_deployment_setup!} in the configuration implementation class
        #
        # Additionally, if specific values are required for particular configuration, they should be
        # defined in {#values} method as a hash
        #
        class Base
          include Helpers::Output

          def initialize(namespace:, ci:, gitlab_domain:)
            @namespace = namespace
            @ci = ci
            @gitlab_domain = gitlab_domain
          end

          class << self
            attr_reader :skip_pre_deployment_setup, :skip_post_deployment_setup

            private

            # Do not run pre deployment setup
            #
            # @return [void]
            def skip_pre_deployment_setup!
              @skip_pre_deployment_setup = true
            end

            # Do not run post deployment setup
            #
            # @return [void]
            def skip_post_deployment_setup!
              @skip_post_deployment_setup = true
            end
          end

          # Steps to be executed before performing helm deployment
          #
          # @return [void]
          def run_pre_deployment_setup
            return if self.class.skip_pre_deployment_setup

            raise(NoMethodError, "run_pre_deployment_setup not implemented")
          end

          # Steps to be executed after helm deployment has been performed
          #
          # @return [void]
          def run_post_deployment_setup
            return if self.class.skip_post_deployment_setup

            raise(NoMethodError, "run_post_deployment_setup not implemented")
          end

          # Values hash containing the values to be passed to helm chart install
          #
          # @return [Hash]
          def values
            {}
          end

          # Deployed app url
          #
          # @return [String]
          def gitlab_url
            "http://gitlab.#{gitlab_domain}"
          end

          private

          attr_reader :namespace, :ci, :gitlab_domain

          # Instance of {Kubectl::Client}
          #
          # @return [Kubectl::Client]
          def kubeclient
            @kubeclient ||= Kubectl::Client.new(namespace)
          end
        end
      end
    end
  end
end
