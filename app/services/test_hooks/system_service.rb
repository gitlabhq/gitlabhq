module TestHooks
  class SystemService < TestHooks::BaseService
    private

    def project
      @project ||= begin
        project = Project.first

        throw(:validation_error, 'Ensure that at least one project exists.') unless project

        project
      end
    end

    def push_events_data
      if project.empty_repo?
        throw(:validation_error, "Ensure project \"#{project.human_name}\" has commits.")
      end

      Gitlab::DataBuilder::Push.build_sample(project, current_user)
    end

    def tag_push_events_data
      if project.repository.tags.empty?
        throw(:validation_error, "Ensure project \"#{project.human_name}\" has tags.")
      end

      Gitlab::DataBuilder::Push.build_sample(project, current_user)
    end

    def repository_update_events_data
      commit = project.commit
      ref = "#{Gitlab::Git::BRANCH_REF_PREFIX}#{project.default_branch}"

      unless commit
        throw(:validation_error, "Ensure project \"#{project.human_name}\" has commits.")
      end

      change = Gitlab::DataBuilder::Repository.single_change(
        commit.parent_id || Gitlab::Git::BLANK_SHA,
        commit.id,
        ref
      )

      Gitlab::DataBuilder::Repository.update(project, current_user, [change], [ref])
    end
  end
end
