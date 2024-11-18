# frozen_string_literal: true

module ProjectAuthorizations
  # How to use this class
  # authorizations_to_add:
  # Rows to insert in the form `[{ user_id: user_id, project_id: project_id, access_level: access_level}, ...]
  #
  # ProjectAuthorizations::Changes.new do |changes|
  #   changes.add(authorizations_to_add)
  #   changes.remove_users_in_project(project, user_ids)
  #   changes.remove_projects_for_user(user, project_ids)
  # end.apply!
  class Changes
    attr_reader :projects_to_remove, :users_to_remove_in_project, :authorizations_to_add

    BATCH_SIZE = 1000
    EVENTS_BATCH_SIZE = 100
    SLEEP_DELAY = 0.1

    def initialize
      @authorizations_to_add = []
      @affected_project_ids = Set.new
      @removed_user_ids = Set.new
      @added_user_ids = Set.new
      yield self
    end

    def add(authorizations_to_add)
      @authorizations_to_add += authorizations_to_add
    end

    def remove_users_in_project(project, user_ids)
      @users_to_remove_in_project = { user_ids: user_ids, scope: project }
    end

    def remove_projects_for_user(user, project_ids)
      @projects_to_remove = { project_ids: project_ids, scope: user }
    end

    def apply!
      delete_authorizations_for_user if should_delete_authorizations_for_user?
      delete_authorizations_for_project if should_delete_authorizations_for_project?
      add_authorizations if should_add_authorization?

      publish_events
    end

    private

    def should_add_authorization?
      authorizations_to_add.present?
    end

    def should_delete_authorizations_for_user?
      user && project_ids.present?
    end

    def should_delete_authorizations_for_project?
      project && user_ids.present?
    end

    def add_authorizations
      insert_all_in_batches(authorizations_to_add)
      @affected_project_ids += authorizations_to_add.pluck(:project_id)
      @added_user_ids += authorizations_to_add.pluck(:user_id)
    end

    def delete_authorizations_for_user
      delete_all_in_batches(resource: user,
        ids_to_remove: project_ids,
        column_name_of_ids_to_remove: :project_id)
      @affected_project_ids += project_ids
      @removed_user_ids.add(user.id)
    end

    def delete_authorizations_for_project
      delete_all_in_batches(resource: project,
        ids_to_remove: user_ids,
        column_name_of_ids_to_remove: :user_id)
      @affected_project_ids << project.id
      @removed_user_ids += user_ids
    end

    def delete_all_in_batches(resource:, ids_to_remove:, column_name_of_ids_to_remove:)
      add_delay = add_delay_between_batches?(entire_size: ids_to_remove.size, batch_size: BATCH_SIZE)
      log_details(entire_size: ids_to_remove.size, batch_size: BATCH_SIZE) if add_delay

      ids_to_remove.each_slice(BATCH_SIZE) do |ids_batch|
        resource.project_authorizations.where(column_name_of_ids_to_remove => ids_batch).delete_all
        perform_delay if add_delay
      end
    end

    def insert_all_in_batches(attributes)
      add_delay = add_delay_between_batches?(entire_size: attributes.size, batch_size: BATCH_SIZE)
      log_details(entire_size: attributes.size, batch_size: BATCH_SIZE) if add_delay

      attributes.each_slice(BATCH_SIZE) do |attributes_batch|
        attributes_batch.each { |attrs| attrs[:is_unique] = true }

        ProjectAuthorization.insert_all(attributes_batch)
        perform_delay if add_delay
      end
    end

    def add_delay_between_batches?(entire_size:, batch_size:)
      # The reason for adding a delay is to give the replica database enough time to
      # catch up with the primary when large batches of records are being added/removed.
      # Hence, we add a delay only if the GitLab installation has a replica database configured.
      entire_size > batch_size &&
        !::Gitlab::Database::LoadBalancing.primary_only?
    end

    def log_details(entire_size:, batch_size:)
      Gitlab::AppLogger.info(
        entire_size: entire_size,
        total_delay: (entire_size / batch_size.to_f).ceil * SLEEP_DELAY,
        message: 'Project authorizations refresh performed with delay',
        **Gitlab::ApplicationContext.current
      )
    end

    def perform_delay
      sleep(SLEEP_DELAY)
    end

    def user
      projects_to_remove&.[](:scope)
    end

    def project_ids
      projects_to_remove&.[](:project_ids)
    end

    def project
      users_to_remove_in_project&.[](:scope)
    end

    def user_ids
      users_to_remove_in_project&.[](:user_ids)
    end

    def publish_events
      publish_removed_event
      publish_added_event
    end

    def publish_removed_event
      return if @removed_user_ids.none?

      events = @affected_project_ids.flat_map do |project_id|
        # NOTE: AuthorizationsRemovedEvent triggers MergeRequests::RemoveUserApprovalRulesWorker, but the approval rules
        # should not be removed when the user's role is just being changed.
        added_user_ids_for_project = @authorizations_to_add
          .select { |data| data[:project_id] == project_id }
          .pluck(:user_id)
        removed_user_ids_for_project = @removed_user_ids - added_user_ids_for_project

        removed_user_ids_for_project.each_slice(EVENTS_BATCH_SIZE).map do |user_ids_batch|
          ::ProjectAuthorizations::AuthorizationsRemovedEvent.new(data: {
            project_id: project_id,
            user_ids: user_ids_batch
          })
        end
      end
      ::Gitlab::EventStore.publish_group(events)
    end

    def publish_added_event
      return if @added_user_ids.none?

      events = @affected_project_ids.each_slice(EVENTS_BATCH_SIZE).flat_map do |project_ids_batch|
        @added_user_ids.each_slice(EVENTS_BATCH_SIZE).map do |user_ids_batch|
          authorization_added_event(project_ids_batch, user_ids_batch)
        end
      end

      ::Gitlab::EventStore.publish_group(events)
    end

    def authorization_added_event(project_ids, user_ids)
      ::ProjectAuthorizations::AuthorizationsAddedEvent.new(data: {
        project_ids: project_ids,
        user_ids: user_ids
      })
    end
  end
end
