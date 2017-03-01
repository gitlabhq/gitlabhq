module Ci
  class RetryBuildService < ::BaseService
    CLONE_ACCESSORS = %i[pipeline project ref tag options commands name
                         allow_failure stage stage_idx trigger_request
                         yaml_variables when environment coverage_regex
                         description tag_list].freeze

    REJECT_ACCESSORS = %i[id status user token coverage trace runner
                          artifacts_expire_at artifacts_file
                          artifacts_metadata artifacts_size
                          created_at updated_at started_at finished_at
                          queued_at erased_by erased_at].freeze

    IGNORE_ACCESSORS = %i[type lock_version target_url gl_project_id
                          deploy job_id base_tags commit_id deployments
                          erased_by_id last_deployment project_id runner_id
                          tag_taggings taggings tags trigger_request_id
                          user_id].freeze

    def execute(build)
      reprocess(build).tap do |new_build|
        build.pipeline.mark_as_processable_after_stage(build.stage_idx)

        new_build.enqueue!

        MergeRequests::AddTodoWhenBuildFailsService
          .new(project, current_user)
          .close(new_build)
      end
    end

    def reprocess(build)
      unless can?(current_user, :update_build, build)
        raise Gitlab::Access::AccessDeniedError
      end

      attributes = CLONE_ACCESSORS.map do |attribute|
        [attribute, build.send(attribute)]
      end

      attributes.push([:user, current_user])

      project.builds.create(Hash[attributes])
    end
  end
end
