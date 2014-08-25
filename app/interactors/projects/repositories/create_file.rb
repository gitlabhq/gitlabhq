module Projects::Repositories
  class CreateFile
    include Interactor::Organizer

    organize [
      Projects::Repositories::Files::Create,
      Projects::Repositories::Push
    ]
  end
end
