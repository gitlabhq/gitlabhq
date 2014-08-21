module Hooks
  class Test < Hooks::Base
    def perform
      hook = context[:hook]
      user = context[:user]
      project = context[:project]

      interactor = Projects::Repository::SamplePush
      result = interactor.perform(project: project, user: user)

      hook.execute(result[:push_data])
    end
  end
end
