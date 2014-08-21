module Projects::Repository::Tag
  class Delete < Projects::Repository::PushBase
    def perform
      tag_name = context[:tag_name]
      project = context[:project]
      repository = project.repository

      tag = repository.find_tag(tag_name)

      # No such tag
      unless tag
        context.fail!(message: 'No such tag')
      end

      context[:oldrev] = tag.target

      repository.rm_tag(tag_name)

      # Prepare data for push
      context[:newrev] = "0000000000000000000000000000000000000000"
      context[:ref] = "refs/heads/" << new_tag.name
    end

    def rollback
      # Return tag
    end
  end
end
