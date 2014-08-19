module Projects::Repositories
  class GetPushCommits < Projects::Base
    def perform
      project = context[:project]
      oldrev = context[:oldrev]
      newrev = context[:newrev]
      ref = context[:ref]

      repository = project.repository

      if push_to_new_branch?(ref, oldrev)
        # Re-find the pushed commits.
        if is_default_branch?(ref, project)
          # Initial push to the default branch. Take the full history of that branch as "newly pushed".
          push_commits = project.repository.commits(newrev)
        else
          # Use the pushed commits that aren't reachable by the default branch
          # as a heuristic. This may include more commits than are actually pushed, but
          # that shouldn't matter because we check for existing cross-references later.
          push_commits = project.repository.commits_between(project.default_branch, newrev)
        end
      else
        push_commits = repository.commits_between(oldrev, newrev)
      end

      context[:push_commits] = push_commits
    end

    def rollback
      context.delete(:push_commits)
    end

    private

    def push_to_new_branch?(ref, oldrev)
      push_to_branch?(ref) && oldrev == "0000000000000000000000000000000000000000"
    end

    def is_default_branch?(ref, project)
      ref == "refs/heads/#{project.default_branch}"
    end

    def push_to_branch?(ref)
      ref =~ /refs\/heads/
    end
  end
end
