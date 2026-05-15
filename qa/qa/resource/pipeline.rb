# frozen_string_literal: true

module QA
  module Resource
    class Pipeline < Base
      attribute :project do
        Resource::Project.fabricate! do |project|
          project.name = 'project-with-pipeline'
        end
      end

      attributes :id,
        :status,
        :ref,
        :sha

      TERMINAL_STATUSES = %w[success failed canceled skipped manual].freeze

      # array in form
      # [
      #   { key: 'UPLOAD_TO_S3', variable_type: 'file', value: true },
      #   { key: 'SOMETHING', variable_type: 'env_var', value: 'yes' }
      # ]
      attribute :variables

      def initialize
        @variables = []
      end

      def fabricate!
        project.visit!

        Page::Project::Menu.perform(&:go_to_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_run_pipeline_button)
        Page::Project::Pipeline::New.perform(&:click_run_pipeline_button)
      end

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError, NoValueError
        super
      end

      def ref
        project.default_branch
      end

      def api_get_path
        "/projects/#{project.id}/pipelines/#{id}"
      end

      def api_jobs_path
        "#{api_get_path}/jobs"
      end

      def api_post_path
        "/projects/#{project.id}/pipeline"
      end

      def api_post_body
        {
          ref: ref,
          variables: variables
        }
      end

      def pipeline_variables
        response = get(request_url("#{api_get_path}/variables"))

        unless response.code == HTTP_STATUS_OK
          raise ResourceQueryError, "Could not get variables. Request returned (#{response.code}): `#{response}`."
        end

        parse_body(response)
      end

      def has_variable?(key:, value:)
        pipeline_variables.any? { |var| var[:key] == key && var[:value] == value }
      end

      def has_no_variable?(key:, value:)
        !pipeline_variables.any? { |var| var[:key] == key && var[:value] == value }
      end

      def pipeline_bridges
        response = get(request_url("#{api_get_path}/bridges"))

        unless response.code == HTTP_STATUS_OK
          raise ResourceQueryError, "Could not get bridges. Request returned (#{response.code}): `#{response}`."
        end

        parse_body(response)
      end

      def downstream_pipeline_id(bridge_name:)
        bridges = pipeline_bridges
        result = bridges.find { |bridge| bridge[:name] == bridge_name }

        unless result
          available_names = bridges.pluck(:name).join(', ')
          raise ResourceQueryError,
            "Bridge '#{bridge_name}' not found. Available bridges: #{available_names}"
        end

        unless result[:downstream_pipeline]
          raise ResourceQueryError, "No downstream pipeline found for bridge '#{bridge_name}'"
        end

        result.dig(:downstream_pipeline, :id)
      end

      def jobs
        parse_body(api_get_from(api_jobs_path))
      end

      def cancel!
        response = post(request_url("#{api_get_path}/cancel"))

        return if response.code == HTTP_STATUS_OK

        raise ResourceActionFailedError,
          "Could not cancel pipeline. Request returned (#{response.code}): `#{response}`."
      end

      def finished?
        TERMINAL_STATUSES.include?(reload!.status)
      end

      def wait_until_finished(max_duration: 60, sleep_interval: 1)
        QA::Support::Waiter.wait_until(
          max_duration: max_duration,
          sleep_interval: sleep_interval,
          message: "Wait for pipeline #{id} to reach a terminal status",
          raise_on_failure: false
        ) { finished? }
      end
    end
  end
end
