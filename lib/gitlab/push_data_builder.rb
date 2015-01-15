module Gitlab
  class PushDataBuilder
    # Produce a hash of post-receive data
    #
    # data = {
    #   before: String,
    #   after: String,
    #   ref: String,
    #   user_id: String,
    #   user_name: String,
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
    def self.build(project, user, oldrev, newrev, ref, commits = [])
      # Total commits count
      commits_count = commits.size

      # Get latest 20 commits ASC
      commits_limited = commits.last(20)

      # Hash to be passed as post_receive_data
      data = {
        before: oldrev,
        after: newrev,
        ref: ref,
        user_id: user.id,
        user_name: user.name,
        project_id: project.id,
        repository: {
          name: project.name,
          url: project.url_to_repo,
          description: project.description,
          homepage: project.web_url,
        },
        commits: [],
        total_commits_count: commits_count
      }

      # For performance purposes maximum 20 latest commits
      # will be passed as post receive hook data.
      commits_limited.each do |commit|
        data[:commits] << commit.hook_attrs(project)
      end

      data
    end

    # This method provide a sample data generated with
    # existing project and commits to test web hooks
    def self.build_sample(project, user)
      commits = project.repository.commits(project.default_branch, nil, 3)
      build(project, user, commits.last.id, commits.first.id, "refs/heads/#{project.default_branch}", commits)
    end
  end
end
