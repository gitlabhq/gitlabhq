# frozen_string_literal: true

module Projects
  module ContainerRepository
    module Gitlab
      class CleanupTagsService < CleanupTagsBaseService
        include ::Projects::ContainerRepository::Gitlab::Timeoutable

        TAGS_PAGE_SIZE = 1000

        def initialize(container_repository:, current_user: nil, params: {})
          super
          @params = params.dup
        end

        def execute
          with_timeout do |start_time, result|
            container_repository.each_tags_page(page_size: TAGS_PAGE_SIZE) do |tags|
              execute_for_tags(tags, result)

              raise TimeoutError if !timeout_disabled? && timeout?(start_time)
            end
          end
        end

        private

        def execute_for_tags(tags, overall_result)
          original_size = tags.size

          filter_out_latest!(tags)
          filter_by_name!(tags)

          tags = filter_by_keep_n(tags)
          tags = filter_by_older_than(tags)

          overall_result[:before_delete_size] += tags.size
          overall_result[:original_size] += original_size

          result = delete_tags(tags)

          overall_result[:deleted_size] += result[:deleted]&.size
          overall_result[:deleted] += result[:deleted]
          overall_result[:status] = result[:status] unless overall_result[:status] == :error
        end

        def with_timeout
          result = success(
            original_size: 0,
            before_delete_size: 0,
            deleted_size: 0,
            deleted: []
          )

          yield Time.zone.now, result

          result
        rescue TimeoutError
          result[:status] = :error

          result
        end

        def filter_by_keep_n(tags)
          partition_by_keep_n(tags).first
        end

        def filter_by_older_than(tags)
          partition_by_older_than(tags).first
        end

        def pushed_at(tag)
          tag.updated_at || tag.created_at
        end

        def timeout_disabled?
          params['disable_timeout'] || false
        end
      end
    end
  end
end
