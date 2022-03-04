# frozen_string_literal: true

module Projects
  module ContainerRepository
    class CleanupTagsService
      include BaseServiceUtility
      include ::Gitlab::Utils::StrongMemoize

      def initialize(container_repository, user = nil, params = {})
        @container_repository = container_repository
        @current_user = user
        @params = params.dup

        @project = container_repository.project
        @tags = container_repository.tags
        tags_size = @tags.size
        @counts = {
          original_size: tags_size,
          cached_tags_count: 0
        }
      end

      def execute
        return error('access denied') unless can_destroy?
        return error('invalid regex') unless valid_regex?

        filter_out_latest
        filter_by_name

        truncate
        populate_from_cache

        filter_keep_n
        filter_by_older_than

        delete_tags.merge(@counts).tap do |result|
          result[:before_delete_size] = @tags.size
          result[:deleted_size] = result[:deleted]&.size

          result[:status] = :error if @counts[:before_truncate_size] != @counts[:after_truncate_size]
        end
      end

      private

      def delete_tags
        return success(deleted: []) unless @tags.any?

        service = Projects::ContainerRepository::DeleteTagsService.new(
          @project,
          @current_user,
          tags: @tags.map(&:name),
          container_expiration_policy: container_expiration_policy
        )

        service.execute(@container_repository)
      end

      def filter_out_latest
        @tags.reject!(&:latest?)
      end

      def order_by_date
        now = DateTime.current
        @tags.sort_by! { |tag| tag.created_at || now }
             .reverse!
      end

      def filter_by_name
        regex_delete = ::Gitlab::UntrustedRegexp.new("\\A#{name_regex_delete || name_regex}\\z")
        regex_retain = ::Gitlab::UntrustedRegexp.new("\\A#{name_regex_keep}\\z")

        @tags.select! do |tag|
          # regex_retain will override any overlapping matches by regex_delete
          regex_delete.match?(tag.name) && !regex_retain.match?(tag.name)
        end
      end

      def filter_keep_n
        return unless keep_n

        order_by_date
        cache_tags(@tags.first(keep_n_as_integer))
        @tags = @tags.drop(keep_n_as_integer)
      end

      def filter_by_older_than
        return unless older_than

        older_than_timestamp = older_than_in_seconds.ago

        @tags, tags_to_keep = @tags.partition do |tag|
          tag.created_at && tag.created_at < older_than_timestamp
        end

        cache_tags(tags_to_keep)
      end

      def can_destroy?
        return true if container_expiration_policy

        can?(@current_user, :destroy_container_image, @project)
      end

      def valid_regex?
        %w(name_regex_delete name_regex name_regex_keep).each do |param_name|
          regex = @params[param_name]
          ::Gitlab::UntrustedRegexp.new(regex) unless regex.blank?
        end
        true
      rescue RegexpError => e
        ::Gitlab::ErrorTracking.log_exception(e, project_id: @project.id)
        false
      end

      def truncate
        @counts[:before_truncate_size] = @tags.size
        @counts[:after_truncate_size] = @tags.size

        return unless throttling_enabled?
        return if max_list_size == 0

        # truncate the list to make sure that after the #filter_keep_n
        # execution, the resulting list will be max_list_size
        truncated_size = max_list_size + keep_n_as_integer

        return if @tags.size <= truncated_size

        @tags = @tags.sample(truncated_size)
        @counts[:after_truncate_size] = @tags.size
      end

      def populate_from_cache
        @counts[:cached_tags_count] = cache.populate(@tags) if caching_enabled?
      end

      def cache_tags(tags)
        cache.insert(tags, older_than_in_seconds) if caching_enabled?
      end

      def cache
        strong_memoize(:cache) do
          ::Gitlab::ContainerRepository::Tags::Cache.new(@container_repository)
        end
      end

      def caching_enabled?
        result = ::Gitlab::CurrentSettings.current_application_settings.container_registry_expiration_policies_caching &&
                 container_expiration_policy &&
                 older_than.present?
        !!result
      end

      def throttling_enabled?
        Feature.enabled?(:container_registry_expiration_policies_throttling)
      end

      def max_list_size
        ::Gitlab::CurrentSettings.current_application_settings.container_registry_cleanup_tags_service_max_list_size.to_i
      end

      def keep_n
        @params['keep_n']
      end

      def keep_n_as_integer
        keep_n.to_i
      end

      def older_than_in_seconds
        strong_memoize(:older_than_in_seconds) do
          ChronicDuration.parse(older_than).seconds
        end
      end

      def older_than
        @params['older_than']
      end

      def name_regex_delete
        @params['name_regex_delete']
      end

      def name_regex
        @params['name_regex']
      end

      def name_regex_keep
        @params['name_regex_keep']
      end

      def container_expiration_policy
        @params['container_expiration_policy']
      end
    end
  end
end
