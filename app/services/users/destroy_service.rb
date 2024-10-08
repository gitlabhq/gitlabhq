# frozen_string_literal: true

module Users
  class DestroyService
    DestroyError = Class.new(StandardError)

    attr_accessor :current_user

    def initialize(current_user)
      @current_user = current_user

      @scheduled_records_gauge = Gitlab::Metrics.gauge(
        :gitlab_ghost_user_migration_scheduled_records_total,
        'The total number of scheduled ghost user migrations'
      )
      @lag_gauge = Gitlab::Metrics.gauge(
        :gitlab_ghost_user_migration_lag_seconds,
        'The waiting time in seconds of the oldest scheduled record for ghost user migration'
      )
    end

    # Asynchronously destroys +user+
    # Migrating the associated user records, and post-migration cleanup is
    # handled by the Users::MigrateRecordsToGhostUserInBatchesWorker cron worker.
    #
    # The operation will fail if the user is the sole owner of any groups. To
    # force the groups to be destroyed, pass `delete_solo_owned_groups: true` in
    # +options+.
    #
    # The user's contributions will be migrated to a global ghost user. To
    # force the contributions to be destroyed, pass `hard_delete: true` in
    # +options+.
    #
    # `hard_delete: true` implies `delete_solo_owned_groups: true`.  To perform
    # a hard deletion without destroying solo-owned groups, pass
    # `delete_solo_owned_groups: false, hard_delete: true` in +options+.
    #

    def execute(user, options = {})
      delete_solo_owned_groups = options.fetch(:delete_solo_owned_groups, options[:hard_delete])

      unless Ability.allowed?(current_user, :destroy_user, user) || options[:skip_authorization]
        raise Gitlab::Access::AccessDeniedError, "#{current_user} tried to destroy user #{user}!"
      end

      if user.solo_owned_organizations.present?
        user.errors.add(:base, 'You must transfer ownership of organizations before you can remove user')
      end

      if !delete_solo_owned_groups && user.solo_owned_groups.present?
        user.errors.add(:base, 'You must transfer ownership or delete groups before you can remove user')
      end

      return user if user.errors.any?

      user.block

      # Load the records. Groups are unavailable after membership is destroyed.
      solo_owned_groups = user.solo_owned_groups.load

      # Load the project_bot user resource. It is unavailable after membership is destroyed.
      options[:project_bot_resource] ||= user.resource_bot_resource

      user.members.each_batch { |batch| batch.destroy_all } # rubocop:disable Cop/DestroyAll

      solo_owned_groups.each do |group|
        Groups::DestroyService.new(group, current_user).execute
      end

      user.personal_projects.each do |project|
        success = ::Projects::DestroyService.new(project, current_user).execute
        raise DestroyError, "Project #{project.id} can't be deleted" unless success
      end

      yield(user) if block_given?

      create_ghost_user(user, options)

      update_metrics
    end

    private

    attr_reader :scheduled_records_gauge, :lag_gauge

    def create_ghost_user(user, options)
      hard_delete = options.fetch(:hard_delete, false)
      Users::GhostUserMigration.create!(
        user: user,
        initiator_user: current_user,
        hard_delete: hard_delete
      )
    rescue ActiveRecord::RecordNotUnique
      # GhostUserMigration was already created by other worker process. Do nothing
    end

    def update_metrics
      update_scheduled_records_gauge
      update_lag_gauge
    end

    def update_scheduled_records_gauge
      # We do not want to issue unbounded COUNT() queries, hence we limit the
      # query to count 1001 records and then approximate the result.
      count = Users::GhostUserMigration.limit(1001).count

      if count == 1001
        # more than 1000 records, approximate count
        min = Users::GhostUserMigration.minimum(:id) || 0
        max = Users::GhostUserMigration.maximum(:id) || 0

        scheduled_records_gauge.set({}, max - min)
      else
        # less than 1000 records, count is accurate
        scheduled_records_gauge.set({}, count)
      end
    end

    def update_lag_gauge
      oldest_job = Users::GhostUserMigration.first
      lag_gauge.set({}, Time.current - oldest_job.created_at)
    end
  end
end

Users::DestroyService.prepend_mod_with('Users::DestroyService')
