module Projects
  class Destroy
    include Interactor::Organizer

    def setup
      context.fail!(message: 'Invalid user') if context[:user].blank?
      context.fail!(message: 'Invalid project') if context[:project].blank?

      unless can?(context[:user], :remove_project, context[:project])
        context.fail!(message: 'User has not permissions to destroy project')
      end
    end

    organize [
      # Order by smaller consequences
      Projects::ExpireRepositoryCache,
      Projects::RemoveSatellite,
      Projects::RemoveRepository,
      Projects::RemoveWiki,
      Projects::TruncateTeam,
      Projects::DestroyProject,
      ExecuteSystemHooks
    ]
  end
end
