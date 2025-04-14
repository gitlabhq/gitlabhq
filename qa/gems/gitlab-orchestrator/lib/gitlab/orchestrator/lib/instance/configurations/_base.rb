# frozen_string_literal: true

module Gitlab
  module Orchestrator
    module Instance
      module Configurations
        # Base class for instance configurations
        #
        class Base
          include Helpers::Output
          include Helpers::Shell

          def initialize(ci: false, gitlab_domain: nil)
            @ci = ci
            @gitlab_domain = gitlab_domain
          end

          # Run pre-installation setup
          #
          # @return [void]
          def run_pre_installation_setup
            # To be implemented by subclasses
          end

          # Run post-installation setup
          #
          # @return [void]
          def run_post_installation_setup
            # To be implemented by subclasses
          end

          # Configuration specific values
          #
          # @return [Hash]
          def values
            {}
          end

          # Gitlab url
          #
          # @return [String]
          def gitlab_url
            raise NotImplementedError, "#{self.class} must implement #gitlab_url"
          end

          protected

          attr_reader :ci, :gitlab_domain
        end
      end
    end
  end
end
