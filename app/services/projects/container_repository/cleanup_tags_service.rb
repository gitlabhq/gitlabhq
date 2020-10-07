# frozen_string_literal: true

module Projects
  module ContainerRepository
    class CleanupTagsService < BaseService
      def execute(container_repository)
        return error('access denied') unless can_destroy?
        return error('invalid regex') unless valid_regex?

        tags = container_repository.tags
        tags = without_latest(tags)
        tags = filter_by_name(tags)
        tags = filter_keep_n(tags)
        tags = filter_by_older_than(tags)

        delete_tags(container_repository, tags)
      end

      private

      def delete_tags(container_repository, tags)
        return success(deleted: []) unless tags.any?

        tag_names = tags.map(&:name)

        Projects::ContainerRepository::DeleteTagsService
          .new(container_repository.project,
               current_user,
               tags: tag_names,
               container_expiration_policy: params['container_expiration_policy'])
          .execute(container_repository)
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
        tags.drop(params['keep_n'].to_i)
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
    end
  end
end
