# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Terraform
        class Tfplan
          RESOURCE_COUNT_INTEGER_LIMIT = 999_999
          RESOURCE_COUNT_STRING_LIMIT = /^[0-9]{1,6}$/

          InvalidResourceCountError = Class.new(StandardError)
          TfplanParserError = Class.new(Gitlab::Ci::Parsers::ParserError)

          def parse!(json_data, terraform_reports, artifact:)
            job_details = job_details(artifact.job)
            job_id = job_details['job_id']
            plan_data = Gitlab::Json.parse(json_data)

            if has_required_keys?(plan_data)
              terraform_reports.add_plan(job_id, valid_tfplan(plan_data, job_details))
            else
              terraform_reports.add_plan(job_id, invalid_tfplan(:missing_json_keys, job_details))
            end
          rescue JSON::ParserError
            terraform_reports.add_plan(job_id, invalid_tfplan(:invalid_json_format, job_details))
          rescue InvalidResourceCountError
            terraform_reports.add_plan(job_id, invalid_tfplan(:invalid_resource_count, job_details))
          rescue StandardError
            details = job_details || {}
            plan_name = job_id || 'failed_tf_plan'
            terraform_reports.add_plan(plan_name, invalid_tfplan(:unknown_error, details))
          end

          private

          def has_required_keys?(plan_data)
            (%w[create update delete] - plan_data.keys).empty?
          end

          def job_details(job)
            {
              'job_id' => job.id.to_s,
              'job_name' => job.name,
              'job_path' => Gitlab::Routing.url_helpers.project_job_path(job.project, job)
            }
          end

          def invalid_tfplan(error_type, job_details)
            job_details.merge('tf_report_error' => error_type)
          end

          def valid_tfplan(plan_data, job_details)
            job_details.merge(
              'create' => sanitize_resource_count(plan_data['create']),
              'delete' => sanitize_resource_count(plan_data['delete']),
              'update' => sanitize_resource_count(plan_data['update'])
            )
          end

          def sanitize_resource_count(value)
            if value.is_a?(Numeric)
              [value, RESOURCE_COUNT_INTEGER_LIMIT].min
            elsif value.is_a?(String) && value.match(RESOURCE_COUNT_STRING_LIMIT)
              value.to_i
            else
              raise InvalidResourceCountError
            end
          end
        end
      end
    end
  end
end
