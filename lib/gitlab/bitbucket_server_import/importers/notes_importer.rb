# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      class NotesImporter
        include ParallelScheduling

        def execute
          bitbucket_server_notes_separate_worker_enabled =
            project.import_data&.data&.dig('bitbucket_server_notes_separate_worker')

          if bitbucket_server_notes_separate_worker_enabled
            import_notes_individually
          else
            import_notes_in_batch
          end

          job_waiter
        end

        private

        attr_reader :project

        def import_notes_in_batch
          project.merge_requests.find_each do |merge_request|
            # Needs to come before `already_processed?` as `jobs_remaining` resets to zero when the job restarts and
            # jobs_remaining needs to be the total amount of enqueued jobs
            job_waiter.jobs_remaining += 1

            next if already_processed?(merge_request)

            job_delay = calculate_job_delay(job_waiter.jobs_remaining)

            sidekiq_worker_class_batch.perform_in(job_delay, project.id, { iid: merge_request.iid }, job_waiter.key)

            mark_as_processed(merge_request)
          end

          job_waiter
        end

        def import_notes_individually
          merge_request_collection.find_each do |merge_request|
            log_info(
              import_stage: 'import_notes',
              message: "importing merge request #{merge_request.iid} notes"
            )

            # The page counter needs to be scoped by parent_record to avoid skipping
            # pages of notes from already imported parent_record. As 2 different MR(s)
            # might share the same page counter.
            page_counter = Gitlab::Import::PageCounter.new(
              project, page_counter_id(merge_request), 'bitbucket-server-importer'
            )
            page = page_counter.current

            log_message = "importing merge request #{merge_request.iid} notes, "
            log_message += "page #{page} using batch-size #{concurrent_import_jobs_limit}"
            loop do
              log_info(
                import_stage: 'import_notes',
                message: log_message
              )

              activities = client.activities(
                project_key, repository_slug, merge_request.iid,
                page_offset: page, limit: concurrent_import_jobs_limit
              ).to_a

              break if activities.empty?

              activities.each do |activity|
                process_comment(merge_request, activity)
              end

              page += 1
              page_counter.set(page)
            end

            page_counter.expire!

            mark_merge_request_processed(merge_request)
          end
        end

        def process_comment(merge_request, activity)
          if activity.comment?
            return enqueue_comment_import(merge_request, 'inline', activity.comment) if activity.inline_comment?

            return enqueue_comment_import(merge_request, 'standalone_notes', activity.comment)
          end

          comment_type = if activity.approved_event?
                           'approved_event'
                         elsif activity.declined_event?
                           'declined_event'
                         elsif activity.merge_event?
                           'merge_event'
                         end

          enqueue_comment_import(merge_request, comment_type, activity) if comment_type
        end

        def enqueue_comment_import(merge_request, comment_type, comment)
          job_waiter.jobs_remaining = Gitlab::Cache::Import::Caching.increment(job_waiter_remaining_cache_key)

          return if already_processed?(comment)

          job_delay = calculate_job_delay(job_waiter.jobs_remaining)

          object_hash = {
            iid: merge_request.iid,
            comment_type: comment_type,
            comment_id: comment.id,
            comment: comment.to_hash.deep_stringify_keys
          }
          sidekiq_worker_class_individual.perform_in(job_delay, project.id, object_hash, job_waiter.key)

          mark_as_processed(comment)
        end

        def sidekiq_worker_class_batch
          ImportPullRequestNotesWorker
        end

        def sidekiq_worker_class_individual
          ImportPullRequestNoteWorker
        end

        def id_for_already_processed_cache(object)
          # :iid is used for the `import_notes_in_batch` which uses `merge_request` as the `object`
          # it can be cleaned up after `import_notes_in_batch` is removed
          object.try(:iid) || generate_activity_key(object)
        end

        def generate_activity_key(object)
          # we need to add key prefix to avoid `id` collision between `activity` and `comment`
          key_prefix = if object.try(:approved_event?) || object.try(:merge_event?) || object.try(:declined_event?)
                         "activity"
                       else
                         "comment"
                       end

          "#{key_prefix}-#{object.id}"
        end

        def collection_method
          :notes
        end

        def merge_request_processed_cache_key
          "bitbucket-server-importer/already-processed/merge_request/#{project.id}"
        end

        def mark_merge_request_processed(merge_request)
          Gitlab::Cache::Import::Caching.set_add(
            merge_request_processed_cache_key,
            merge_request.iid
          )
        end

        def already_processed_merge_requests
          Gitlab::Cache::Import::Caching.values_from_set(merge_request_processed_cache_key)
        end

        def merge_request_collection
          project.merge_requests.where.not(iid: already_processed_merge_requests) # rubocop: disable CodeReuse/ActiveRecord -- no need to move this to ActiveRecord model
        end

        def page_counter_id(merge_request)
          "merge_request/#{merge_request.id}/#{collection_method}"
        end
      end
    end
  end
end
