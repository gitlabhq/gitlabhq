# frozen_string_literal: true

module Projects
  module ContainerRepository
    module ThirdParty
      class DeleteTagsService
        include BaseServiceUtility

        def initialize(container_repository, tag_names)
          @container_repository = container_repository
          @tag_names = tag_names
        end

        # Replace a tag on the registry with a dummy tag.
        # This is a hack as the registry doesn't support deleting individual
        # tags. This code effectively pushes a dummy image and assigns the tag to it.
        # This way when the tag is deleted only the dummy image is affected.
        # This is used to preserve compatibility with third-party registries that
        # don't support fast delete.
        # See https://gitlab.com/gitlab-org/gitlab/issues/15737 for a discussion
        def execute
          return success(deleted: []) if @tag_names.empty?

          # generates the blobs for the dummy image
          dummy_manifest = @container_repository.client.generate_empty_manifest(@container_repository.path)
          return error('could not generate manifest') if dummy_manifest.nil?

          deleted_tags = replace_tag_manifests(dummy_manifest)

          # Deletes the dummy image
          # All created tag digests are the same since they all have the same dummy image.
          # a single delete is sufficient to remove all tags with it
          if deleted_tags.any? && @container_repository.delete_tag(deleted_tags.each_value.first)
            success(deleted: deleted_tags.keys)
          else
            error("could not delete tags: #{@tag_names.join(', ')}".truncate(1000))
          end
        end

        private

        # update the manifests of the tags with the new dummy image
        def replace_tag_manifests(dummy_manifest)
          deleted_tags = @tag_names.map do |name|
            digest = @container_repository.client.put_tag(@container_repository.path, name, dummy_manifest)
            next unless digest

            [name, digest]
          end.compact.to_h

          # make sure the digests are the same (it should always be)
          digests = deleted_tags.values.uniq

          # rubocop: disable CodeReuse/ActiveRecord
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ArgumentError.new('multiple tag digests')) if digests.many?

          deleted_tags
        end
      end
    end
  end
end
