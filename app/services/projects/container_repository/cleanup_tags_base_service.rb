# frozen_string_literal: true

module Projects
  module ContainerRepository
    class CleanupTagsBaseService < BaseContainerRepositoryService
      private

      def filter_out_latest!(tags)
        return unless keep_latest

        tags.reject!(&:latest?)
      end

      def filter_by_name!(tags)
        regex_delete = ::Gitlab::UntrustedRegexp.new("\\A#{name_regex_delete || name_regex}\\z")
        regex_retain = ::Gitlab::UntrustedRegexp.new("\\A#{name_regex_keep}\\z")

        tags.select! do |tag|
          # regex_retain will override any overlapping matches by regex_delete
          regex_delete.match?(tag.name) && !regex_retain.match?(tag.name)
        end
      end

      # Should return [tags_to_delete, tags_to_keep]
      def partition_by_keep_n(tags)
        return [tags, []] unless keep_n

        tags = order_by_date_desc(tags)

        tags.partition.with_index { |_, index| index >= keep_n_as_integer }
      end

      # Should return [tags_to_delete, tags_to_keep]
      def partition_by_older_than(tags)
        return [tags, []] unless older_than

        older_than_timestamp = older_than_in_seconds.ago

        tags.partition do |tag|
          timestamp = pushed_at(tag)

          timestamp && timestamp < older_than_timestamp
        end
      end

      def order_by_date_desc(tags)
        now = DateTime.current
        tags.sort_by! { |tag| pushed_at(tag) || now }
            .reverse!
      end

      def delete_tags(tags)
        return success(deleted: []) unless tags.any?

        service = Projects::ContainerRepository::DeleteTagsService.new(
          project,
          current_user,
          tags: tags.map(&:name),
          container_expiration_policy: container_expiration_policy
        )

        service.execute(container_repository)
      end

      def older_than
        params['older_than']
      end

      def name_regex_delete
        params['name_regex_delete']
      end

      def name_regex
        params['name_regex']
      end

      def name_regex_keep
        params['name_regex_keep']
      end

      def container_expiration_policy
        params['container_expiration_policy']
      end

      def keep_n
        params['keep_n']
      end

      def keep_latest
        params.fetch('keep_latest', true)
      end

      def project
        container_repository.project
      end

      def keep_n_as_integer
        keep_n.to_i
      end

      def older_than_in_seconds
        strong_memoize(:older_than_in_seconds) do
          ChronicDuration.parse(older_than).seconds
        end
      end
    end
  end
end
