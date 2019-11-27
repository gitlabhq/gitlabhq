# frozen_string_literal: true

module Projects
  module ContainerRepository
    class CleanupTagsService < BaseService
      def execute(container_repository)
        return error('feature disabled') unless can_use?
        return error('access denied') unless can_admin?

        tags = container_repository.tags
        tags_by_digest = group_by_digest(tags)

        tags = without_latest(tags)
        tags = filter_by_name(tags)
        tags = with_manifest(tags)
        tags = order_by_date(tags)
        tags = filter_keep_n(tags)
        tags = filter_by_older_than(tags)

        deleted_tags = delete_tags(tags, tags_by_digest)

        success(deleted: deleted_tags.map(&:name))
      end

      private

      def delete_tags(tags_to_delete, tags_by_digest)
        deleted_digests = group_by_digest(tags_to_delete).select do |digest, tags|
          delete_tag_digest(tags, tags_by_digest[digest])
        end

        deleted_digests.values.flatten
      end

      def delete_tag_digest(tags, other_tags)
        # Issue: https://gitlab.com/gitlab-org/gitlab-foss/issues/21405
        # we have to remove all tags due
        # to Docker Distribution bug unable
        # to delete single tag
        return unless tags.count == other_tags.count

        # delete all tags
        tags.map(&:unsafe_delete)
      end

      def group_by_digest(tags)
        tags.group_by(&:digest)
      end

      def without_latest(tags)
        tags.reject(&:latest?)
      end

      def with_manifest(tags)
        tags.select(&:valid?)
      end

      def order_by_date(tags)
        now = DateTime.now
        tags.sort_by { |tag| tag.created_at || now }.reverse
      end

      def filter_by_name(tags)
        regex = Gitlab::UntrustedRegexp.new("\\A#{params['name_regex']}\\z")

        tags.select do |tag|
          regex.scan(tag.name).any?
        end
      end

      def filter_keep_n(tags)
        tags.drop(params['keep_n'].to_i)
      end

      def filter_by_older_than(tags)
        return tags unless params['older_than']

        older_than = ChronicDuration.parse(params['older_than']).seconds.ago

        tags.select do |tag|
          tag.created_at && tag.created_at < older_than
        end
      end

      def can_admin?
        can?(current_user, :admin_container_image, project)
      end

      def can_use?
        Feature.enabled?(:container_registry_cleanup, project, default_enabled: true)
      end
    end
  end
end
