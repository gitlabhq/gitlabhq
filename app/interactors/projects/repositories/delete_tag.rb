module Projects::Repositories
  class DeleteTag
    include Interactor::Organizer

    organize [
      Projects::Repositories::Tag::Delete,
      Projects::Repositories::Push
    ]
  end
end
