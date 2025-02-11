# frozen_string_literal: true

module Integrations
  module Base
    module MockCi
      extend ActiveSupport::Concern

      ALLOWED_STATES = %w[failed canceled running pending success success-with-warnings skipped not_found].freeze

      class_methods do
        def title
          'MockCI'
        end

        def description
          _('Mock an external CI integration.')
        end

        def to_param
          'mock_ci'
        end
      end

      included do
        include Base::Ci
        prepend EnableSslVerification

        validates :mock_service_url, presence: true, public_url: true, if: :activated?

        field :mock_service_url,
          title: -> { s_('ProjectService|Mock CI URL') },
          description: -> { _('URL of the Mock CI integration.') },
          placeholder: 'http://localhost:4004',
          required: true

        # Return complete url to build page
        #
        # Ex.
        #   http://jenkins.example.com:8888/job/test1/scm/bySHA1/12d65c
        #
        def build_page(sha, _ref)
          Gitlab::Utils.append_path(
            mock_service_url,
            "#{project.namespace.path}/#{project.path}/status/#{sha}")
        end

        # Return string with build status or :error symbol
        #
        # Allowed states: 'success', 'failed', 'running', 'pending', 'skipped'
        #
        # Ex.
        #   @service.commit_status('13be4ac', 'master')
        #   # => 'success'
        #
        #   @service.commit_status('2abe4ac', 'dev')
        #   # => 'running'
        #
        def commit_status(sha, _ref)
          response = Gitlab::HTTP.get(commit_status_path(sha), verify: enable_ssl_verification)
          read_commit_status(response)
        rescue Errno::ECONNREFUSED
          :error
        end

        def commit_status_path(sha)
          Gitlab::Utils.append_path(
            mock_service_url,
            "#{project.namespace.path}/#{project.path}/status/#{sha}.json")
        end

        def read_commit_status(response)
          return :pending if response.code == 404
          return :error unless response.code == 200

          begin
            status = Gitlab::Json.parse(response.body).try(:fetch, 'status', nil)
            return status if ALLOWED_STATES.include?(status)
          rescue JSON::ParserError
          end

          :error
        end

        def testable?
          false
        end
      end
    end
  end
end
