# frozen_string_literal: true

namespace :gitlab do
  require 'set'

  namespace :cleanup do
    desc "GitLab | Cleanup | Block users that have been removed in LDAP"
    task block_removed_ldap_users: :gitlab_environment do
      warn_user_is_not_gitlab
      block_flag = ENV['BLOCK']

      User.find_each do |user|
        next unless user.ldap_user?

        print "#{user.name} (#{user.ldap_identity.extern_uid}) ..."

        if Gitlab::Auth::Ldap::Access.allowed?(user)
          puts " [OK]".color(:green)
        elsif block_flag
          user.block! unless user.blocked?
          puts " [BLOCKED]".color(:red)
        else
          puts " [NOT IN LDAP]".color(:yellow)
        end
      end

      unless block_flag
        puts "To block these users run this command with BLOCK=true".color(:yellow)
      end
    end

    desc "GitLab | Cleanup | Clean orphaned project uploads"
    task project_uploads: :gitlab_environment do
      warn_user_is_not_gitlab

      cleaner = Gitlab::Cleanup::ProjectUploads.new(logger: logger)
      cleaner.run!(dry_run: dry_run?)

      if dry_run?
        logger.info "To clean up these files run this command with DRY_RUN=false".color(:yellow)
      end
    end

    desc 'GitLab | Cleanup | Clean orphan remote upload files that do not exist in the db'
    task remote_upload_files: :environment do
      cleaner = Gitlab::Cleanup::RemoteUploads.new(logger: logger)
      cleaner.run!(dry_run: dry_run?)

      if dry_run?
        logger.info "To cleanup these files run this command with DRY_RUN=false".color(:yellow)
      end
    end

    desc 'GitLab | Cleanup | Clean orphan job artifact files'
    task orphan_job_artifact_files: :gitlab_environment do
      warn_user_is_not_gitlab

      cleaner = Gitlab::Cleanup::OrphanJobArtifactFiles.new(dry_run: dry_run?, niceness: niceness, logger: logger)
      cleaner.run!

      if dry_run?
        logger.info "To clean up these files run this command with DRY_RUN=false".color(:yellow)
      end
    end

    desc 'GitLab | Cleanup | Clean orphan LFS file references'
    task orphan_lfs_file_references: :gitlab_environment do
      warn_user_is_not_gitlab

      project = find_project

      unless project
        logger.info "Specify the project with PROJECT_ID={number} or PROJECT_PATH={namespace/project-name}".color(:red)
        exit
      end

      cleaner = Gitlab::Cleanup::OrphanLfsFileReferences.new(
        project,
        dry_run: dry_run?,
        logger: logger
      )

      cleaner.run!

      if dry_run?
        logger.info "To clean up these files run this command with DRY_RUN=false".color(:yellow)
      end
    end

    desc 'GitLab | Cleanup | Clean orphan LFS files'
    task orphan_lfs_files: :gitlab_environment do
      warn_user_is_not_gitlab

      number_of_removed_files = RemoveUnreferencedLfsObjectsWorker.new.perform

      logger.info "Removed unreferenced LFS files: #{number_of_removed_files}".color(:green)
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

    # rubocop:disable Gitlab/RailsLogger
    def logger
      return @logger if defined?(@logger)

      @logger = if Rails.env.development? || Rails.env.production?
                  Logger.new($stdout).tap do |stdout_logger|
                    stdout_logger.extend(ActiveSupport::Logger.broadcast(Rails.logger))
                    stdout_logger.level = debug? ? Logger::DEBUG : Logger::INFO
                  end
                else
                  Rails.logger
                end
    end
    # rubocop:enable Gitlab/RailsLogger
  end
end
