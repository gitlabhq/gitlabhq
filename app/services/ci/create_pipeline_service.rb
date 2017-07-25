module Ci
  class CreatePipelineService < BaseService
    attr_reader :pipeline

    def execute(source)
      @pipeline = Ci::Pipeline.new(
        source: source,
        project: project,
        ref: ref,
        sha: sha,
        before_sha: before_sha,
        tag: tag?,
        user: current_user,
        pipeline_schedule: pipeline_schedule
      )

      return pipeline if skip_ci?

      validate!

      Ci::Pipeline.transaction do
        pipeline.save!

        yield(pipeline) if block_given?

        Ci::CreatePipelineStagesService
          .new(project, current_user)
          .execute(pipeline)
      end

      update_relations!
      pipeline.process!

      rescue Exception => e
        pipeline.errors.add(:base, "Failed to create a pipeline: #{e}")
      ensure
        return pipeline
    end

    private

    def validate!
      raise 'Pipeline is disabled' unless project.builds_enabled?
      raise 'Insufficient permissions to create a new pipeline' unless can?(current_user, :create_pipeline, project)
      raise 'Reference not found' unless branch? || tag?
      raise 'Commit not found' unless commit

      unless pipeline.config_processor
        raise "Missing #{pipeline.ci_yaml_file_path} file" unless pipeline.ci_yaml_file

        pipeline.drop if save_on_errors
        raise pipeline.yaml_errors
      end

      raise 'No stages / jobs for this pipeline.' unless pipeline.has_stage_seeds?
    end

    def update_relations!
      update_merge_requests_head_pipeline
      cancel_pending_pipelines if project.auto_cancel_pending_pipelines?
      pipeline_created_counter.increment(source: source)
    end

    def update_merge_requests_head_pipeline
      return unless pipeline.latest?

      MergeRequest.where(source_project: @pipeline.project, source_branch: @pipeline.ref)
        .update_all(head_pipeline_id: @pipeline.id)
    end

    def skip_ci?
      return false unless pipeline.git_commit_message

      if pipeline.git_commit_message =~ /\[(ci[ _-]skip|skip[ _-]ci)\]/i && !ignore_skip_ci
        pipeline.skip if save_on_errors

        return true
      end

      return false
    end

    end

    def cancel_pending_pipelines
      Gitlab::OptimisticLocking.retry_lock(auto_cancelable_pipelines) do |cancelables|
        cancelables.find_each do |cancelable|
          cancelable.auto_cancel_running(pipeline)
        end
      end
    end

    def auto_cancelable_pipelines
      project.pipelines
        .where(ref: pipeline.ref)
        .where.not(id: pipeline.id)
        .where.not(sha: project.repository.sha_from_ref(pipeline.ref))
        .created_or_pending
    end

    def commit
      @commit ||= project.commit(origin_sha || origin_ref)
    end

    def sha
      commit.try(:id)
    end

    def before_sha
      params[:checkout_sha] || params[:before] || Gitlab::Git::BLANK_SHA
    end

    def origin_sha
      params[:checkout_sha] || params[:after]
    end

    def origin_ref
      params[:ref]
    end

    def ignore_skip_ci
      params[:ignore_skip_ci] || false
    end

    def save_on_errors
      params[:save_on_errors] || true
    end

    def pipeline_schedule
      params[:pipeline_schedule]
    end

    def branch?
      project.repository.ref_exists?(Gitlab::Git::BRANCH_REF_PREFIX + ref)
    end

    def tag?
      project.repository.ref_exists?(Gitlab::Git::TAG_REF_PREFIX + ref)
    end

    def ref
      Gitlab::Git.ref_name(origin_ref)
    end

    def valid_sha?
      origin_sha && origin_sha != Gitlab::Git::BLANK_SHA
    end

    # def error(message)
    #   pipeline.errors.add(:base, message)
    #   pipeline
    # end

    def pipeline_created_counter
      @pipeline_created_counter ||= Gitlab::Metrics.counter(:pipelines_created_total, "Counter of pipelines created")
    end
  end
end
