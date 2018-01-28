module Gitlab
  module DataBuilder
    module Push
      extend self

      SAMPLE_DATA =
        {
          object_kind: "push",
          event_name: "push",
          before: "95790bf891e76fee5e1747ab589903a6a1f80f22",
          after: "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
          ref: "refs/heads/master",
          checkout_sha: "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
          message: "Hello World",
          user_id: 4,
          user_name: "John Smith",
          user_email: "john@example.com",
          user_avatar: "https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80",
          project_id: 15,
          commits: [
            {
              id: "c5feabde2d8cd023215af4d2ceeb7a64839fc428",
              message: "Add simple search to projects in public area",
              timestamp: "2013-05-13T18:18:08+00:00",
              url: "https://test.example.com/gitlab/gitlabhq/commit/c5feabde2d8cd023215af4d2ceeb7a64839fc428",
              author: {
                name: "Test User",
                email: "test@example.com"
              }
            }
          ],
          total_commits_count: 1
        }.freeze

      # Produce a hash of post-receive data
      #
      # data = {
      #   before: String,
      #   after: String,
      #   ref: String,
      #   user_id: String,
      #   user_name: String,
      #   user_username: String,
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
      def build(project, user, oldrev, newrev, ref, commits = [], message = nil, commits_count: nil)
        commits = Array(commits)

        # Total commits count
        commits_count ||= commits.size

        # Get latest 20 commits ASC
        commits_limited = commits.last(20)

        # For performance purposes maximum 20 latest commits
        # will be passed as post receive hook data.
        # n+1: https://gitlab.com/gitlab-org/gitlab-ce/issues/38259
        commit_attrs = Gitlab::GitalyClient.allow_n_plus_1_calls do
          commits_limited.map do |commit|
            commit.hook_attrs(with_changed_files: true)
          end
        end

        type = Gitlab::Git.tag_ref?(ref) ? 'tag_push' : 'push'

        # Hash to be passed as post_receive_data
        {
          object_kind: type,
          event_name: type,
          before: oldrev,
          after: newrev,
          ref: ref,
          checkout_sha: checkout_sha(project.repository, newrev, ref),
          message: message,
          user_id: user.id,
          user_name: user.name,
          user_username: user.username,
          user_email: user.email,
          user_avatar: user.avatar_url(only_path: false),
          project_id: project.id,
          project: project.hook_attrs,
          commits: commit_attrs,
          total_commits_count: commits_count,
          # DEPRECATED
          repository: project.hook_attrs.slice(:name, :url, :description, :homepage,
                                               :git_http_url, :git_ssh_url, :visibility_level)
        }
      end

      # This method provide a sample data generated with
      # existing project and commits to test webhooks
      def build_sample(project, user)
        ref = "#{Gitlab::Git::BRANCH_REF_PREFIX}#{project.default_branch}"
        commits = project.repository.commits(project.default_branch.to_s, limit: 3) rescue []

        build(project, user, commits.last&.id, commits.first&.id, ref, commits)
      end

      def sample_data
        SAMPLE_DATA
      end

      private

      def checkout_sha(repository, newrev, ref)
        # Checkout sha is nil when we remove branch or tag
        return if Gitlab::Git.blank_ref?(newrev)

        # Find sha for tag, except when it was deleted.
        if Gitlab::Git.tag_ref?(ref)
          tag_name = Gitlab::Git.ref_name(ref)
          tag = repository.find_tag(tag_name)

          if tag
            commit = repository.commit(tag.dereferenced_target)
            commit.try(:sha)
          end
        else
          newrev
        end
      end
    end
  end
end
