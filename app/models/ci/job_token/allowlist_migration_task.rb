# frozen_string_literal: true

module Ci
  module JobToken
    class AllowlistMigrationTask
      include Gitlab::Utils::StrongMemoize
      include Gitlab::InternalEventsTracking

      attr_reader :only_ids, :exclude_ids

      INPUT_ID_LIMIT = 1000

      def initialize(only_ids: nil, exclude_ids: nil, preview: nil, user: nil, output_stream: $stdout, concurrency: 1)
        @only_ids = parse_project_ids(only_ids)
        @exclude_ids = parse_project_ids(exclude_ids)
        @preview = !preview.blank?
        @user = user
        @success_count = Concurrent::AtomicFixnum.new(0)
        @failed_projects = Concurrent::Array.new
        @output_stream = output_stream
        @concurrency = concurrency.to_i
      end

      def execute
        if valid_configuration?
          @output_stream.puts preview_banner if preview_mode?
          @output_stream.puts start_message

          migrate!

          @output_stream.puts finish_message
          @output_stream.puts summary_report
        else
          @output_stream.puts configuration_error_banner
        end
      end

      private

      def migrate!
        if @only_ids.present?
          migrate_batch(@only_ids)
        else
          ProjectCiCdSetting.each_batch do |batch|
            batch = batch.where(inbound_job_token_scope_enabled: false)
            project_ids = batch.pluck(:project_id) - @exclude_ids # rubocop: disable Database/AvoidUsingPluckWithoutLimit -- pluck limited to batch size
            chunk_size = (project_ids.size / @concurrency.to_f).ceil

            next if chunk_size == 0

            project_id_chunks = project_ids.each_slice(chunk_size).to_a

            Parallel.each(project_id_chunks, in_threads: @concurrency) do |project_id_chunk|
              ApplicationRecord.connection_pool.with_connection do
                migrate_batch(project_id_chunk)
              end
            end
          end
        end
      end

      def migrate_batch(project_ids)
        Project.where(id: project_ids).preload(:ci_cd_settings).find_each do |project|
          status, message = migrate_project(project)

          if status == 'success'
            @success_count.increment
          else
            @failed_projects.concat([project.id])
          end

          @output_stream.puts log_migrate_result(status, project, message)
        end
      end

      def migrate_project(project)
        return 'success', nil if preview_mode?

        result = perform_migration!(project)

        return 'success', nil if result.success?

        ['error', result.message]

      rescue StandardError => error
        ['error', error.message]
      end

      def log_migrate_result(status, project, message = nil)
        if preview_mode?
          "Would have migrated project id: #{project.id}."
        elsif status == 'success'
          "Migrated project id: #{project.id}."
        else
          "Error migrating project id: #{project.id}, error: #{message}"
        end
      end

      def perform_migration!(project)
        ::Ci::JobToken::AutopopulateAllowlistService # rubocop:disable CodeReuse/ServiceClass -- This class is not an ActiveRecord model
          .new(project, @user)
          .unsafe_execute!
      end

      def valid_configuration?
        (@only_ids.empty? || @exclude_ids.empty?) &&
          @only_ids.size <= INPUT_ID_LIMIT &&
          @exclude_ids.size <= INPUT_ID_LIMIT
      end

      def preview_mode?
        @preview
      end

      def start_message
        if preview_mode?
          "\nMigrating project(s) in preview mode, concurrency: #{@concurrency}...\n\n"
        else
          "\nMigrating project(s), concurrency: #{@concurrency}...\n\n"
        end
      end

      def finish_message
        if preview_mode?
          "\nMigration complete in preview mode.\n\n"
        else
          "\nMigration complete.\n\n"
        end
      end

      def summary_report
        return if preview_mode?

        failure_count = @failed_projects.length
        success_count = @success_count.value
        report_lines = []
        report_lines << "Summary: \n"
        report_lines << "  #{success_count} project(s) successfully migrated, #{failure_count} error(s) reported.\n"

        if failure_count > 0
          report_lines << "  The following #{failure_count} project id(s) failed to migrate:\n"
          report_lines << "    #{@failed_projects.join(', ')}" # -- pluck limited by array size
        end

        report_lines.join
      end

      def preview_banner
        banner("PREVIEW MODE ENABLED")
      end

      def configuration_error_banner
        error = if @only_ids.size > INPUT_ID_LIMIT || @exclude_ids.size > INPUT_ID_LIMIT
                  "must contain less than #{INPUT_ID_LIMIT} items"
                else
                  "cannot both be set"
                end

        banner("ERROR: ONLY_PROJECT_IDS and EXCLUDE_PROJECT_IDS #{error}, try again.")
      end

      def parse_project_ids(ids_string)
        return [] if ids_string.blank?

        ids_string.split(',')
          .map(&:strip)
          .map(&:to_i)
          .uniq
      end

      def banner(message)
        output = []
        output << "##########"
        output << "#"
        output << "# #{message}"
        output << "#"
        output << "##########"
        output.join("\n")
      end
    end
  end
end
