module Ci
  class CreateCommitService
    def execute(project, user, params)
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
      commit = project.gl_project.ensure_ci_commit(sha)
      unless commit.skip_ci?
        commit.update_committed!
        commit.create_builds(ref, tag, user)
      end

      commit
    end
  end
end
