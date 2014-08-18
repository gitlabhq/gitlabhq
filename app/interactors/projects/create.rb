module Projects
  class Create
    include Interactor::Organizer

    organize [
      Projects::CreateProject,
      Projects::CreateBareRepository,
      Projects::CreateWiki,
      Projects::AddFirstMaster,
      Projects::UpdateActivityCache,
      ExecuteSystemHooks
    ]
  end
end
