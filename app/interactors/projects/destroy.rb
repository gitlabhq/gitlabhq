module Projects
  class Destroy
    include Interactor::Organizer

    organize [
      # Order by smaller consequences
      Projects::ExpireCache,
      Projects::RemoveSatellite,
      Projects::RemoveRepository,
      Projects::RemoveWiki,
      Projects::TruncateTeam,
      Projects::DestroyProject,
      ExecuteSystemHooks
    ]
  end
end
