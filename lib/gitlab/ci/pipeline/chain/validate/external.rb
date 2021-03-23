# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Validate
          class External < Chain::Base
            include Chain::Helpers

            InvalidResponseCode = Class.new(StandardError)

            VALIDATION_REQUEST_TIMEOUT = 5
            ACCEPTED_STATUS = 200
            DOT_COM_REJECTED_STATUS = 406
            GENERAL_REJECTED_STATUS = (400..499).freeze

            def perform!
              return unless enabled?

              pipeline_authorized = validate_external

              log_message = pipeline_authorized ? 'authorized' : 'not authorized'
              Gitlab::AppLogger.info(message: "Pipeline #{log_message}", project_id: @pipeline.project.id, user_id: @pipeline.user.id)

              error('External validation failed', drop_reason: :external_validation_failure) unless pipeline_authorized
            end

            def break?
              @pipeline.errors.any?
            end

            private

            def enabled?
              return true unless Gitlab.com?

              ::Feature.enabled?(:ci_external_validation_service, project, default_enabled: :yaml)
            end

            def validate_external
              return true unless validation_service_url

              # 200 - accepted
              # 406 - not accepted on GitLab.com
              # 4XX - not accepted for other installations
              # everything else - accepted and logged
              response_code = validate_service_request.code
              case response_code
              when ACCEPTED_STATUS
                true
              when rejected_status
                false
              else
                raise InvalidResponseCode, "Unsupported response code received from Validation Service: #{response_code}"
              end
            rescue => ex
              Gitlab::ErrorTracking.track_exception(ex, project_id: project.id)

              true
            end

            def rejected_status
              if Gitlab.com?
                DOT_COM_REJECTED_STATUS
              else
                GENERAL_REJECTED_STATUS
              end
            end

            def validate_service_request
              Gitlab::HTTP.post(
                validation_service_url, timeout: VALIDATION_REQUEST_TIMEOUT,
                body: validation_service_payload(@pipeline, @command.yaml_processor_result.stages_attributes)
              )
            end

            def validation_service_url
              ENV['EXTERNAL_VALIDATION_SERVICE_URL']
            end

            def validation_service_payload(pipeline, stages_attributes)
              {
                project: {
                  id: pipeline.project.id,
                  path: pipeline.project.full_path
                },
                user: {
                  id: pipeline.user.id,
                  username: pipeline.user.username,
                  email: pipeline.user.email
                },
                pipeline: {
                  sha: pipeline.sha,
                  ref: pipeline.ref,
                  type: pipeline.source
                },
                builds: builds_validation_payload(stages_attributes)
              }.to_json
            end

            def builds_validation_payload(stages_attributes)
              stages_attributes.map { |stage| stage[:builds] }.flatten
                .map(&method(:build_validation_payload))
            end

            def build_validation_payload(build)
              {
                name: build[:name],
                stage: build[:stage],
                image: build.dig(:options, :image, :name),
                services: build.dig(:options, :services)&.map { |service| service[:name] },
                script: [
                  build.dig(:options, :before_script),
                  build.dig(:options, :script),
                  build.dig(:options, :after_script)
                ].flatten.compact
              }
            end
          end
        end
      end
    end
  end
end
