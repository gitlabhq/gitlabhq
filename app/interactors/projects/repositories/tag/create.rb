module Projects::Repository::Tag
  class Create < Projects::Repository::PushBase
    def perform
      tag_name = context[:tag_name]
      project = context[:project]
      repository = project.repository

      repository.add_tag(tag_name, ref)
      new_tag = repository.find_tag(tag_name)

      context[:tag] = new_tag if new_tag
    end
  end
end
