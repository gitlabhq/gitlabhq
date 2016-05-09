module Ci
  class CreatePipelineService < BaseService
    def execute
      unless ref_names.include?(params[:ref])
        raise ArgumentError, 'Reference not found'
      end

      unless commit
        raise ArgumentError, 'Commit not found'
      end

      unless can?(current_user, :create_pipeline, project)
        raise RuntimeError, 'Insufficient permissions to create a new pipeline'
      end

      Ci::Commit.transaction do
        unless pipeline.config_processor
          raise ArgumentError, pipeline.yaml_errors || 'Missing .gitlab-ci.yml file'
        end

        pipeline.save!
        pipeline.create_builds(current_user)
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

    def pipeline
      @pipeline ||= project.ci_commits.new(sha: commit.id, ref: params[:ref], before_sha: Gitlab::Git::BLANK_SHA)
    end
  end
end