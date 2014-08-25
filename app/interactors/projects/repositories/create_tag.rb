module Projects::Repositories
  class CreateTag
    include Interactor::Organizer

    organize [
      Projects::Repository::Tag::Create,
      Projects::Repositories::Push
    ]
  end
end
