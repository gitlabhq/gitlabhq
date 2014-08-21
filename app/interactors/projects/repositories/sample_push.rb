module Projects::Repositories
  class SamplePush < Project::Base
    include Interactor::Organizer

    def setup
      super

      context.fail!(message: 'Invalid user') if context[:user].blank?

      project = context[:project]

      push_commits = project.repository.commits(project.default_branch, nil, 3)
      context[:push_commits] = push_commits
      context[:oldrev] = push_commits.last.id
      context[:newrev] = push_commits.first.id
      context[:ref] = "refs/heads/#{project.default_branch}"
    end

    organize [Projects::Repositories::PostReceiveData]
  end
end
