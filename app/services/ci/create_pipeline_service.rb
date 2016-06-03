module Ci
  class CreatePipelineService < BaseService
    def execute
      pipeline = project.ci_commits.new(params)

      unless ref_names.include?(params[:ref])
        pipeline.errors.add(:base, 'Reference not found')
        return pipeline
      end

      unless commit
        pipeline.errors.add(:base, 'Commit not found')
        return pipeline
      end

      unless can?(current_user, :create_pipeline, project)
        pipeline.errors.add(:base, 'Insufficient permissions to create a new pipeline')
        return pipeline
      end

      begin
        Ci::Commit.transaction do
          pipeline.sha = commit.id

          unless pipeline.config_processor
            pipeline.errors.add(:base, pipeline.yaml_errors || 'Missing .gitlab-ci.yml file')
            raise ActiveRecord::Rollback
          end

          pipeline.save!
          pipeline.create_builds(current_user)
        end
      rescue
        pipeline.errors.add(:base, 'The pipeline could not be created. Please try again.')
      end

      pipeline
    end

    private

    def ref_names
      @ref_names ||= project.repository.ref_names
    end

    def commit
      @commit ||= project.commit(params[:ref])
    end
  end
end
