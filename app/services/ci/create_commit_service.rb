module Ci
  class CreateCommitService
    def execute(project, params)
      before_sha = params[:before]
      sha = params[:checkout_sha] || params[:after]
      origin_ref = params[:ref]
      
      unless origin_ref && sha.present?
        return false
      end

      ref = origin_ref.gsub(/\Arefs\/(tags|heads)\//, '')

      # Skip branch removal
      if sha == Ci::Git::BLANK_SHA
        return false
      end

      tag = origin_ref.start_with?('refs/tags/')
      push_data = {
        before: before_sha,
        after: sha,
        ref: ref,
        user_name: params[:user_name],
        user_email: params[:user_email],
        repository: params[:repository],
        commits: params[:commits],
        total_commits_count: params[:total_commits_count],
        ci_yaml_file: params[:ci_yaml_file]
      }

      commit = project.gl_project.ensure_ci_commit(sha)
      commit.update_committed!
      commit.create_builds(ref, tag, push_data)

      commit
    end
  end
end
