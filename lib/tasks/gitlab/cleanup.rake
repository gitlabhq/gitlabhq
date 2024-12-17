# frozen_string_literal: true

namespace :gitlab do
  namespace :cleanup do
    desc "GitLab | Cleanup | Block users that have been removed in LDAP"
    task block_removed_ldap_users: :gitlab_environment do
      warn_user_is_not_gitlab
      block_flag = ENV['BLOCK']

      User.find_each do |user|
        next unless user.ldap_user?

        print "#{user.name} (#{user.ldap_identity.extern_uid}) ..."

        if Gitlab::Auth::Ldap::Access.allowed?(user)
          puts Rainbow(" [OK]").green
        elsif block_flag
          user.block! unless user.blocked?
          puts Rainbow(" [BLOCKED]").red
        else
          puts Rainbow(" [NOT IN LDAP]").yellow
        end
      end

      unless block_flag
        puts Rainbow("To block these users run this command with BLOCK=true").yellow
      end
    end

    desc "GitLab | Cleanup | Clean orphaned project uploads"
    task project_uploads: :gitlab_environment do
      warn_user_is_not_gitlab

      cleaner = Gitlab::Cleanup::ProjectUploads.new(logger: logger)
      cleaner.run!(dry_run: dry_run?)

      if dry_run?
        logger.info Rainbow("To clean up these files run this command with DRY_RUN=false").yellow
      end
    end

    desc 'GitLab | Cleanup | Clean orphan remote upload files that do not exist in the db'
    task remote_upload_files: :environment do
      cleaner = Gitlab::Cleanup::RemoteUploads.new(logger: logger)
      cleaner.run!(dry_run: dry_run?)

      if dry_run?
        logger.info Rainbow("To cleanup these files run this command with DRY_RUN=false").yellow
      end
    end

    desc 'GitLab | Cleanup | Clean orphan job artifact files in local storage'
    task orphan_job_artifact_files: :gitlab_environment do
      warn_user_is_not_gitlab

      cleaner = Gitlab::Cleanup::OrphanJobArtifactFiles.new(dry_run: dry_run?, niceness: niceness, logger: logger)
      cleaner.run!

      if dry_run?
        logger.info Rainbow("To clean up these files run this command with DRY_RUN=false").yellow
      end
    end

    desc 'GitLab | Cleanup | Generate a CSV file of orphan job artifact objects stored in the @final directory'
    task :list_orphan_job_artifact_final_objects, [:provider] => :gitlab_environment do |_, args|
      warn_user_is_not_gitlab

      force_restart = ENV['FORCE_RESTART'].present?
      filename = ENV['FILENAME']

      begin
        generator = Gitlab::Cleanup::OrphanJobArtifactFinalObjects::GenerateList.new(
          provider: args.provider,
          force_restart: force_restart,
          filename: filename,
          logger: logger
        )

        generator.run!

        logger.info(
          Rainbow("To delete these objects run gitlab:cleanup:delete_orphan_job_artifact_final_objects").yellow
        )
      rescue Gitlab::Cleanup::OrphanJobArtifactFinalObjects::GenerateList::UnsupportedProviderError => e
        abort %(#{e.message}
Usage: rake "gitlab:cleanup:list_orphan_job_artifact_final_objects[provider]")
      end
    end

    desc 'GitLab | Cleanup | Delete orphan job artifact objects stored in the @final directory based on the CSV file'
    task delete_orphan_job_artifact_final_objects: :gitlab_environment do
      warn_user_is_not_gitlab

      force_restart = ENV['FORCE_RESTART'].present?
      filename = ENV['FILENAME']

      processor = Gitlab::Cleanup::OrphanJobArtifactFinalObjects::ProcessList.new(
        force_restart: force_restart,
        filename: filename,
        logger: logger
      )

      processor.run!
    end

    desc 'GitLab | Cleanup | Rollback deleted final orphan job artifact objects (GCP only)'
    task rollback_deleted_orphan_job_artifact_final_objects: :gitlab_environment do
      warn_user_is_not_gitlab

      force_restart = ENV['FORCE_RESTART'].present?
      filename = ENV['FILENAME']

      processor = Gitlab::Cleanup::OrphanJobArtifactFinalObjects::RollbackDeletedObjects.new(
        force_restart: force_restart,
        filename: filename,
        logger: logger
      )

      processor.run!
    end

    desc 'GitLab | Cleanup | Clean orphan LFS file references'
    task orphan_lfs_file_references: :gitlab_environment do
      warn_user_is_not_gitlab

      project = find_project

      unless project
        logger.info Rainbow("Specify the project with PROJECT_ID={number} or PROJECT_PATH={namespace/project-name}").red
        exit
      end

      cleaner = Gitlab::Cleanup::OrphanLfsFileReferences.new(
        project,
        dry_run: dry_run?,
        logger: logger
      )

      cleaner.run!

      if dry_run?
        logger.info Rainbow("To clean up these files run this command with DRY_RUN=false").yellow
      end
    end

    desc "GitLab | Cleanup | Clean missed source branches to be deleted"
    task remove_missed_source_branches: :gitlab_environment do
      warn_user_is_not_gitlab

      logger.info("Gitlab|Cleanup|Clean up missed source branches|Executed by #{gitlab_user}")

      if ENV['LIMIT_TO_DELETE'].present? && !ENV['LIMIT_TO_DELETE'].to_i.between?(1, 10000)
        logger.info("Please specify a limit between 1 and 10000")
        next
      end

      if ENV['BATCH_SIZE'].present? && !ENV['BATCH_SIZE'].to_i.between?(1, 1000)
        logger.info("Please specify a batch size between 1 and 1000")
        next
      end

      batch_size = ENV['BATCH_SIZE'].present? ? ENV['BATCH_SIZE'].to_i : 1000
      limit = ENV['LIMIT_TO_DELETE'].present? ? ENV['LIMIT_TO_DELETE'].to_i : 10000

      project = find_project
      user = User.find_by_id(ENV['USER_ID']&.to_i)

      number_deleted = 0

      # rubocop: disable Layout/LineLength
      MergeRequest
        .merged
        .where(project: project)
        .each_batch(of: batch_size) do |mrs|
          matching_mrs = mrs.where(
            "merge_params LIKE '%force_remove_source_branch: ''1''%' OR merge_params LIKE '%should_remove_source_branch: ''1''%'"
          )

          branches_to_delete = []

          # rubocop: enable Layout/LineLength
          matching_mrs.each do |mr|
            next unless mr.source_branch_exists? && mr.can_remove_source_branch?(user)

            # Ensuring that only this MR exists for the source branch
            if MergeRequest.where(project: project).where.not(id: mr.id).where(source_branch: mr.source_branch).exists?
              next
            end

            latest_diff_sha = mr.latest_merge_request_diff.head_commit_sha

            next unless latest_diff_sha

            branches_to_delete << { reference: mr.source_branch_ref, old_sha: latest_diff_sha,
new_sha: Gitlab::Git::SHA1_BLANK_SHA }

            break if number_deleted + branches_to_delete.size >= limit
          end

          if dry_run?
            logger.info "DRY RUN: Branches to be deleted in batch #{branches_to_delete.join(',')}"
            logger.info "DRY RUN: Count: #{branches_to_delete.size}"
          else
            project.repository.raw.update_refs(branches_to_delete)
            logger.info "Branches deleted #{branches_to_delete.join(',')}"
          end

          number_deleted += branches_to_delete.size

          break if number_deleted >= limit
        end
    end

    desc 'GitLab | Cleanup | Clean orphan LFS files'
    task orphan_lfs_files: :gitlab_environment do
      warn_user_is_not_gitlab

      number_of_removed_files = RemoveUnreferencedLfsObjectsWorker.new.perform

      logger.info Rainbow("Removed unreferenced LFS files: #{number_of_removed_files}").green
    end

    namespace :sessions do
      desc "GitLab | Cleanup | Sessions | Clean ActiveSession lookup keys"
      task active_sessions_lookup_keys: :gitlab_environment do
        session_key_pattern = "#{Gitlab::Redis::Sessions::USER_SESSIONS_LOOKUP_NAMESPACE}:*"
        last_save_check = Time.at(0)
        wait_time = 10.seconds
        cursor = 0
        total_users_scanned = 0

        Gitlab::Redis::Sessions.with do |redis|
          begin
            cursor, keys = redis.scan(cursor, match: session_key_pattern)
            total_users_scanned += keys.count

            if last_save_check < Time.now - 1.second
              while redis.info('persistence')['rdb_bgsave_in_progress'] == '1'
                puts "BGSAVE in progress, waiting #{wait_time} seconds"
                sleep(wait_time)
              end
              last_save_check = Time.now
            end

            user = Struct.new(:id)

            keys.each do |key|
              user_id = key.split(':').last

              removed = []
              active = ActiveSession.cleaned_up_lookup_entries(redis, user.new(user_id), removed)

              if removed.any?
                puts "deleted #{removed.count} out of #{active.count + removed.count} lookup keys for User ##{user_id}"
              end
            end
          end while cursor.to_i != 0

          puts "--- All done! Total number of scanned users: #{total_users_scanned}"
        end
      end
    end

    def remove?
      ENV['REMOVE'] == 'true'
    end

    def dry_run?
      ENV['DRY_RUN'] != 'false'
    end

    def debug?
      ENV['DEBUG'].present?
    end

    def niceness
      ENV['NICENESS'].presence
    end

    def find_project
      if ENV['PROJECT_ID']
        Project.find_by_id(ENV['PROJECT_ID']&.to_i)
      elsif ENV['PROJECT_PATH']
        Project.find_by_full_path(ENV['PROJECT_PATH'])
      end
    end

    def logger
      return @logger if defined?(@logger)

      @logger = if Rails.env.development? || Rails.env.production?
                  Logger.new($stdout).tap do |stdout_logger|
                    stdout_logger.level = debug? ? Logger::DEBUG : Logger::INFO

                    if ::Gitlab.next_rails?
                      ActiveSupport::BroadcastLogger.new(stdout_logger, Rails.logger, Rails.logger)
                    else
                      stdout_logger.extend(ActiveSupport::Logger.broadcast(Rails.logger))
                    end
                  end
                else
                  Rails.logger
                end
    end
  end
end
