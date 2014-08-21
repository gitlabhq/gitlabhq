module Projects::Repositories
  class DeleteFile
    include Interactor::Organizer

    organize [
      Projects::Repositories::Files::Delete,
      Projects::Repositories::Push
    ]
  end
end
