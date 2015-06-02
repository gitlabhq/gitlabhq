module Files
  class BaseService < ::BaseService
    attr_reader :ref, :path

    def initialize(project, user, params, ref, path = nil)
      @project, @current_user, @params = project, user, params.dup
      @ref = ref
      @path = path
    end

    private

    def repository
      project.repository
    end

    def after_commit(sha)
      commit = repository.commit(sha)
      full_ref = 'refs/heads/' + (params[:new_branch] || ref)
      old_sha = commit.parent_id || Gitlab::Git::BLANK_SHA
      GitPushService.new.execute(project, current_user, old_sha, sha, full_ref)
    end
  end
end
