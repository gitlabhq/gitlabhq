# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Terraform
        class Tfplan
          TfplanParserError = Class.new(Gitlab::Ci::Parsers::ParserError)

          def parse!(json_data, terraform_reports, artifact:)
            plan_data = Gitlab::Json.parse(json_data)

            raise TfplanParserError, 'Tfplan missing required key' unless has_required_keys?(plan_data)

            terraform_reports.add_plan(artifact.job.id.to_s, tfplan(plan_data, artifact.job))
          rescue JSON::ParserError
            raise TfplanParserError, 'JSON parsing failed'
          rescue
            raise TfplanParserError, 'Tfplan parsing failed'
          end

          private

          def has_required_keys?(plan_data)
            (%w[create update delete] - plan_data.keys).empty?
          end

          def tfplan(plan_data, artifact_job)
            {
              'create' => plan_data['create'].to_i,
              'delete' => plan_data['delete'].to_i,
              'job_name' => artifact_job.options.dig(:artifacts, :name).to_s,
              'job_path' => Gitlab::Routing.url_helpers.project_job_path(artifact_job.project, artifact_job),
              'update' => plan_data['update'].to_i
            }
          end
        end
      end
    end
  end
end
