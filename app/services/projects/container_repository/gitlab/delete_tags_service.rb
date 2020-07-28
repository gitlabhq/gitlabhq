# frozen_string_literal: true

module Projects
  module ContainerRepository
    module Gitlab
      class DeleteTagsService
        include BaseServiceUtility

        def initialize(container_repository, tag_names)
          @container_repository = container_repository
          @tag_names = tag_names
        end

        # Delete tags by name with a single DELETE request. This is only supported
        # by the GitLab Container Registry fork. See
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23325 for details.
        def execute
          return success(deleted: []) if @tag_names.empty?

          deleted_tags = @tag_names.select do |name|
            @container_repository.delete_tag_by_name(name)
          end

          deleted_tags.any? ? success(deleted: deleted_tags) : error('could not delete tags')
        end
      end
    end
  end
end
