# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Terraform
        class Tfplan
          TfplanParserError = Class.new(Gitlab::Ci::Parsers::ParserError)

          def parse!(json_data, terraform_reports, artifact:)
            tfplan = Gitlab::Json.parse(json_data).tap do |parsed_data|
              parsed_data['job_path'] = Gitlab::Routing.url_helpers.project_job_path(
                artifact.job.project, artifact.job
              )
            end

            raise TfplanParserError, 'Tfplan missing required key' unless valid_supported_keys?(tfplan)

            terraform_reports.add_plan(artifact.filename, tfplan)
          rescue JSON::ParserError
            raise TfplanParserError, 'JSON parsing failed'
          rescue
            raise TfplanParserError, 'Tfplan parsing failed'
          end

          private

          def valid_supported_keys?(tfplan)
            tfplan.keys == %w[create update delete job_path]
          end
        end
      end
    end
  end
end
