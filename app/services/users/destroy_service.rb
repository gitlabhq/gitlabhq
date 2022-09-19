# frozen_string_literal: true

module Users
  class DestroyService
    DestroyError = Class.new(StandardError)

    attr_accessor :current_user

    def initialize(current_user)
      @current_user = current_user
    end

    # Synchronously destroys +user+
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
    # To make the service asynchronous, a new behaviour is being introduced
    # behind the user_destroy_with_limited_execution_time_worker feature flag.
    # Migrating the associated user records, and post-migration cleanup is
    # handled by the Users::MigrateRecordsToGhostUserWorker cron worker.
    def execute(user, options = {})
      delete_solo_owned_groups = options.fetch(:delete_solo_owned_groups, options[:hard_delete])

      unless Ability.allowed?(current_user, :destroy_user, user) || options[:skip_authorization]
        raise Gitlab::Access::AccessDeniedError, "#{current_user} tried to destroy user #{user}!"
      end

      if !delete_solo_owned_groups && user.solo_owned_groups.present?
        user.errors.add(:base, 'You must transfer ownership or delete groups before you can remove user')
        return user
      end

      user.block

      # Load the records. Groups are unavailable after membership is destroyed.
      solo_owned_groups = user.solo_owned_groups.load

      user.members.each_batch { |batch| batch.destroy_all } # rubocop:disable Style/SymbolProc, Cop/DestroyAll

      solo_owned_groups.each do |group|
        Groups::DestroyService.new(group, current_user).execute
      end

      namespace = user.namespace
      namespace.prepare_for_destroy

      user.personal_projects.each do |project|
        success = ::Projects::DestroyService.new(project, current_user).execute
        raise DestroyError, "Project #{project.id} can't be deleted" unless success
      end

      yield(user) if block_given?

      hard_delete = options.fetch(:hard_delete, false)

      if Feature.enabled?(:user_destroy_with_limited_execution_time_worker)
        Users::GhostUserMigration.create!(user: user,
                                          initiator_user: current_user,
                                          hard_delete: hard_delete)

      else
        MigrateToGhostUserService.new(user).execute(hard_delete: options[:hard_delete])

        response = Snippets::BulkDestroyService.new(current_user, user.snippets)
                                               .execute(skip_authorization: hard_delete)
        raise DestroyError, response.message if response.error?

        # Rails attempts to load all related records into memory before
        # destroying: https://github.com/rails/rails/issues/22510
        # This ensures we delete records in batches.
        user.destroy_dependent_associations_in_batches(exclude: [:snippets])
        user.nullify_dependent_associations_in_batches

        # Destroy the namespace after destroying the user since certain methods may depend on the namespace existing
        user_data = user.destroy
        namespace.destroy

        user_data
      end
    end
  end
end

Users::DestroyService.prepend_mod_with('Users::DestroyService')
