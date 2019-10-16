# frozen_string_literal: true

module Projects
  module ContainerRepository
    class DeleteTagsService < BaseService
      def execute(container_repository)
        return error('access denied') unless can?(current_user, :destroy_container_image, project)

        tag_names = params[:tags]
        return error('not tags specified') if tag_names.blank?

        if can_use?
          smart_delete(container_repository, tag_names)
        else
          unsafe_delete(container_repository, tag_names)
        end
      end

      private

      def unsafe_delete(container_repository, tag_names)
        deleted_tags = tag_names.select do |tag_name|
          container_repository.tag(tag_name).unsafe_delete
        end

        return error('could not delete tags') if deleted_tags.empty?

        success(deleted: deleted_tags)
      end

      # Replace a tag on the registry with a dummy tag.
      # This is a hack as the registry doesn't support deleting individual
      # tags. This code effectively pushes a dummy image and assigns the tag to it.
      # This way when the tag is deleted only the dummy image is affected.
      # See https://gitlab.com/gitlab-org/gitlab/issues/15737 for a discussion
      def smart_delete(container_repository, tag_names)
        # generates the blobs for the dummy image
        dummy_manifest = container_repository.client.generate_empty_manifest(container_repository.path)

        # update the manifests of the tags with the new dummy image
        tag_digests = tag_names.map do |name|
          container_repository.client.put_tag(container_repository.path, name, dummy_manifest)
        end

        # make sure the digests are the same (it should always be)
        tag_digests.uniq!

        # rubocop: disable CodeReuse/ActiveRecord
        Gitlab::Sentry.track_exception(ArgumentError.new('multiple tag digests')) if tag_digests.many?

        # Deletes the dummy image
        # All created tag digests are the same since they all have the same dummy image.
        # a single delete is sufficient to remove all tags with it
        if container_repository.delete_tag_by_digest(tag_digests.first)
          success(deleted: tag_names)
        else
          error('could not delete tags')
        end
      end

      def can_use?
        Feature.enabled?(:container_registry_smart_delete, project, default_enabled: true)
      end
    end
  end
end
