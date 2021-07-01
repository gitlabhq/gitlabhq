# frozen_string_literal: true

# For an example companion mocking service, see https://gitlab.com/gitlab-org/gitlab-mock-ci-service
module Integrations
  class MockCi < BaseCi
    ALLOWED_STATES = %w[failed canceled running pending success success-with-warnings skipped not_found].freeze

    prop_accessor :mock_service_url
    validates :mock_service_url, presence: true, public_url: true, if: :activated?

    def title
      'MockCI'
    end

    def description
      'Mock an external CI'
    end

    def self.to_param
      'mock_ci'
    end

    def fields
      [
        {
          type: 'text',
          name: 'mock_service_url',
          title: s_('ProjectService|Mock service URL'),
          placeholder: 'http://localhost:4004',
          required: true
        }
      ]
    end

    # Return complete url to build page
    #
    # Ex.
    #   http://jenkins.example.com:8888/job/test1/scm/bySHA1/12d65c
    #
    def build_page(sha, ref)
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
    def commit_status(sha, ref)
      response = Gitlab::HTTP.get(commit_status_path(sha), verify: false, use_read_total_timeout: true)
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
      return :error unless response.code == 200 || response.code == 404

      status = if response.code == 404
                 'pending'
               else
                 response['status']
               end

      if status.present? && ALLOWED_STATES.include?(status)
        status
      else
        :error
      end
    end

    def can_test?
      false
    end
  end
end
