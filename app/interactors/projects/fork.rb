module Projects
  class Fork
    include Interactor::Organizer

    organize [
      Projects::ForkProject,
      Projects::AddFirstMaster,
      Projects::EnsureSatelliteExists
    ]
  end
end
