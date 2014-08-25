module Projects::Repositories
  class UpdateFile
    include Interactor::Organizer

    organize [
      Projects::Repositories::Files::Update,
      Projects::Repositories::Push
    ]
  end
end
