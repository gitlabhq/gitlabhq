module Projects::Repositories
  class PostReceiveData < Projects::Base
    def setup
      if context[:push_commits].blank?
        repository = context[:project].repository
        context[:push_commits] = repository.commits_between(context[:oldrev],
                                                            context[:newrev])
      end
    end
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
    def perform
      project = context[:project]
      oldrev = context[:oldrev]
      newrev = context[:newrev]
      ref = context[:ref]

      # Hash to be passed as post_receive_data
      # For branch and tag we have different hash
      # But for difference between them are in 2 addition field for branch
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
        }
      }

      if pushed_to_branch?(ref)
        push_commits = context[:push_commits]

        # Total commits count
        push_commits_count = push_commits.size
        data[:total_commits_count] = push_commits_count

        # Get latest 20 commits ASC
        push_commits_limited = push_commits.last(20)

        # For performance purposes maximum 20 latest commits
        # will be passed as post receive hook data.
        data[:commits] =  []

        push_commits_limited.each do |commit|
          data[:commits] << {
            id: commit.id,
            message: commit.safe_message,
            timestamp: commit.committed_date.xmlschema,
            url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/commit/#{commit.id}",
            author: {
              name: commit.author_name,
              email: commit.author_email
            }
          }
        end
      end

      context[:push_data] = data
    end

    def rollback
      context.delete(:push_data)
    end

    private

    def pushed_branch?(ref)
      ref =~ /refs\/heads/
    end
  end
end
