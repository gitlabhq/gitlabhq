module Projects
  class SyncContext < BaseContext
    include Gitlab::ShellAdapter

    def initialize(project, user, opts)
      @project, @current_user = project, user

      @url = opts[:url] || 'origin'
      @source_branch = opts[:source_branch] || 'master'
      @dest_branch = opts[:dest_branch] || @source_branch
    end

    def execute
      if @project.imported?
        # Here we need to take the cached count
        pre_tags = @project.repository.tag_names.count
        oldhead = @project.repository.commit('HEAD').id

        gitlab_shell.sync_imported_repository(@project.path_with_namespace, @url, @source_branch, @dest_branch)

        # Here we need to take the uncached count
        post_tags = @project.repository.raw_repository.tag_names.count
        newhead = @project.repository.commit('HEAD').id

        commits_changed = @project.repository.commits_between(oldhead, newhead).count
        tags_changed = post_tags - pre_tags

        if tags_changed != 0 || commits_changed != 0
          # If something changed force a new reload
          GitPushService.new.execute(@project, @current_user, oldhead, newhead, @dest_branch)
        end

        if commits_changed > 0
          notice = "Project was successfully updated: #{commits_changed.abs} new commits."
        elsif commits_changed < 0
          notice = "Project was successfully updated: #{commits_changed.abs} commits removed."
        else
          notice = "No new commits for this project."
        end

        if tags_changed > 0
          notice += " #{tags_changed.abs} new tags."
        elsif tags_changed < 0
          notice += " #{tags_changed.abs} tags removed."
        else
          notice += "No new tags for this project."
        end

        notice
      else
        raise Exception.new('repository was not imported. Unable to update.')
      end
    end
  end
end
