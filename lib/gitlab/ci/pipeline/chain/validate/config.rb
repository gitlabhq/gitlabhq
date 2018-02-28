module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Validate
          class Config < Chain::Base
            include Chain::Helpers

            def perform!
              unless @pipeline.config_processor
                unless @pipeline.ci_yaml_file
                  return error("Missing #{@pipeline.ci_yaml_file_path} file")
                end

                if @command.save_incompleted && @pipeline.has_yaml_errors?
                  @pipeline.drop!(:config_error)
                end

                return error(@pipeline.yaml_errors)
              end

              unless @pipeline.has_stage_seeds?
                return error('No stages / jobs for this pipeline.')
              end
            end

            def break?
              @pipeline.errors.any? || @pipeline.persisted?
            end
          end
        end
      end
    end
  end
end
