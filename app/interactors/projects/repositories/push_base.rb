module Projects::Repositories
  class PushBase < Projects::Base
    def setup
      project = context[:project]
      user = context[:user]

      # Dont allow user to remove branch if he is not allowed to push
      unless user.can?(:push_code, project)
        context.fail!(message: 'You dont have push access to repo')
      end
    end
  end
end
