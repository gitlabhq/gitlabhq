module Ci
  class CreatePipelineService < BaseService
    def execute
      pipeline = project.pipelines.new(params)
      pipeline.user = current_user

      unless ref_names.include?(params[:ref])
        pipeline.errors.add(:base, 'Reference not found')
        return pipeline
      end

      if commit
        pipeline.sha = commit.id
      else
        pipeline.errors.add(:base, 'Commit not found')
        return pipeline
      end

      unless can?(current_user, :create_pipeline, project)
        pipeline.errors.add(:base, 'Insufficient permissions to create a new pipeline')
        return pipeline
      end

      unless pipeline.config_processor
        pipeline.errors.add(:base, pipeline.yaml_errors || 'Missing .gitlab-ci.yml file')
        return pipeline
      end

      pipeline.save!

      unless pipeline.create_builds(current_user)
        pipeline.errors.add(:base, 'No builds for this pipeline.')
      end

      pipeline.save
      pipeline.touch
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
