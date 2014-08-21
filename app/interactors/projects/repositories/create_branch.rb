module Projects::Repositories
  class CreateBranch
    include Interactor::Organizer

    organize [
      Projects::Repositories::Branch::Create,
      Projects::Repositories::Push
    ]
  end
end
