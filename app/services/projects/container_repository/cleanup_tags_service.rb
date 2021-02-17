# frozen_string_literal: true

module Projects
  module ContainerRepository
    class CleanupTagsService < BaseService
      def execute(container_repository)
        return error('access denied') unless can_destroy?
        return error('invalid regex') unless valid_regex?

        tags = container_repository.tags
        original_size = tags.size

        tags = without_latest(tags)
        tags = filter_by_name(tags)

        before_truncate_size = tags.size
        tags = truncate(tags)
        after_truncate_size = tags.size

        tags = filter_keep_n(tags)
        tags = filter_by_older_than(tags)

        delete_tags(container_repository, tags).tap do |result|
          result[:original_size] = original_size
          result[:before_truncate_size] = before_truncate_size
          result[:after_truncate_size] = after_truncate_size
          result[:before_delete_size] = tags.size
          result[:deleted_size] = result[:deleted]&.size

          result[:status] = :error if before_truncate_size != after_truncate_size
        end
      end

      private

      def delete_tags(container_repository, tags)
        return success(deleted: []) unless tags.any?

        tag_names = tags.map(&:name)

        service = Projects::ContainerRepository::DeleteTagsService.new(
          container_repository.project,
          current_user,
          tags: tag_names,
          container_expiration_policy: params['container_expiration_policy']
        )

        service.execute(container_repository)
      end

      def without_latest(tags)
        tags.reject(&:latest?)
      end

      def order_by_date(tags)
        now = DateTime.current
        tags.sort_by { |tag| tag.created_at || now }.reverse
      end

      def filter_by_name(tags)
        regex_delete = ::Gitlab::UntrustedRegexp.new("\\A#{params['name_regex_delete'] || params['name_regex']}\\z")
        regex_retain = ::Gitlab::UntrustedRegexp.new("\\A#{params['name_regex_keep']}\\z")

        tags.select do |tag|
          # regex_retain will override any overlapping matches by regex_delete
          regex_delete.match?(tag.name) && !regex_retain.match?(tag.name)
        end
      end

      def filter_keep_n(tags)
        return tags unless params['keep_n']

        tags = order_by_date(tags)
        tags.drop(keep_n)
      end

      def filter_by_older_than(tags)
        return tags unless params['older_than']

        older_than = ChronicDuration.parse(params['older_than']).seconds.ago

        tags.select do |tag|
          tag.created_at && tag.created_at < older_than
        end
      end

      def can_destroy?
        return true if params['container_expiration_policy']

        can?(current_user, :destroy_container_image, project)
      end

      def valid_regex?
        %w(name_regex_delete name_regex name_regex_keep).each do |param_name|
          regex = params[param_name]
          ::Gitlab::UntrustedRegexp.new(regex) unless regex.blank?
        end
        true
      rescue RegexpError => e
        ::Gitlab::ErrorTracking.log_exception(e, project_id: project.id)
        false
      end

      def truncate(tags)
        return tags unless throttling_enabled?
        return tags if max_list_size == 0

        # truncate the list to make sure that after the #filter_keep_n
        # execution, the resulting list will be max_list_size
        truncated_size = max_list_size + keep_n

        return tags if tags.size <= truncated_size

        tags.sample(truncated_size)
      end

      def throttling_enabled?
        Feature.enabled?(:container_registry_expiration_policies_throttling)
      end

      def max_list_size
        ::Gitlab::CurrentSettings.current_application_settings.container_registry_cleanup_tags_service_max_list_size.to_i
      end

      def keep_n
        params['keep_n'].to_i
      end
    end
  end
end
