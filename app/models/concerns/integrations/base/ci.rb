# frozen_string_literal: true

# Base module for CI integrations
# List methods you need to implement to get your CI integration
# working with GitLab merge requests
module Integrations
  module Base
    module Ci
      extend ActiveSupport::Concern

      class_methods do
        def supported_events
          %w[push]
        end
      end

      included do
        attribute :category, default: 'ci'
      end

      def valid_token?(token)
        respond_to?(:token) &&
          self.token.present? &&
          ActiveSupport::SecurityUtils.secure_compare(token, self.token)
      end

      # Return complete url to build page
      #
      # Ex.
      #   http://jenkins.example.com:8888/job/test1/scm/bySHA1/12d65c
      #
      def build_page(sha, ref)
        # override this method in the including class
      end

      # Return string with build status or :error symbol
      #
      # Allowed states: 'success', 'failed', 'running', 'pending', 'skipped'
      #
      #
      # Ex.
      #   @integration.commit_status('13be4ac', 'master')
      #   # => 'success'
      #
      #   @integration.commit_status('2abe4ac', 'dev')
      #   # => 'running'
      #
      #
      def commit_status(sha, ref)
        # override this method in the including class
      end
    end
  end
end
