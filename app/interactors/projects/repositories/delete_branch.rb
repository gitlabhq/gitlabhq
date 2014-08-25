module Projects::Repositories
  class DeleteBranch
    include Interactor::Organizer

    organize [
      Projects::Repositories::Branch::Delete,
      Projects::Repositories::Push
    ]
  end
end
