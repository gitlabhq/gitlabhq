module Gitlab
  class PushDataBuilder
    class << self
      # Produce a hash of post-receive data
      #
      # data = {
      #   before: String,
      #   after: String,
      #   ref: String,
      #   user_id: String,
      #   user_name: String,
      #   user_email: String
      #   project_id: String,
      #   repository: {
      #     name: String,
      #     url: String,
      #     description: String,
      #     homepage: String,
      #   },
      #   commits: Array,
      #   total_commits_count: Fixnum
      # }
      #
      def build(project, user, oldrev, newrev, ref, commits = [], message = nil)
        # Total commits count
        commits_count = commits.size

        # Get latest 20 commits ASC
        commits_limited = commits.last(20)

        # For performance purposes maximum 20 latest commits
        # will be passed as post receive hook data.
        commit_attrs = commits_limited.map(&:hook_attrs)

        type = Gitlab::Git.tag_ref?(ref) ? "tag_push" : "push"
        # Hash to be passed as post_receive_data
        data = {
          object_kind: type,
          before: oldrev,
          after: newrev,
          ref: ref,
          checkout_sha: checkout_sha(project.repository, newrev, ref),
          message: message,
          user_id: user.id,
          user_name: user.name,
          user_email: user.email,
          project_id: project.id,
          repository: {
            name: project.name,
            url: project.url_to_repo,
            description: project.description,
            homepage: project.web_url,
            git_http_url: project.http_url_to_repo,
            git_ssh_url: project.ssh_url_to_repo,
            visibility_level: project.visibility_level
          },
          commits: commit_attrs,
          total_commits_count: commits_count
        }

        data
      end

      # This method provide a sample data generated with
      # existing project and commits to test web hooks
      def build_sample(project, user)
        commits = project.repository.commits(project.default_branch, nil, 3)
        ref = "#{Gitlab::Git::BRANCH_REF_PREFIX}#{project.default_branch}"
        build(project, user, commits.last.id, commits.first.id, ref, commits)
      end

      def checkout_sha(repository, newrev, ref)
        # Checkout sha is nil when we remove branch or tag
        return if Gitlab::Git.blank_ref?(newrev)

        # Find sha for tag, except when it was deleted.
        if Gitlab::Git.tag_ref?(ref)
          tag_name = Gitlab::Git.ref_name(ref)
          tag = repository.find_tag(tag_name)

          if tag
            commit = repository.commit(tag.target)
            commit.try(:sha)
          end
        else
          newrev
        end
      end
    end
  end
end
