# frozen_string_literal: true

module JiraConnectSubscriptions
  class CreateService < ::JiraConnectSubscriptions::BaseService
    include Gitlab::Utils::StrongMemoize
    MERGE_REQUEST_SYNC_BATCH_SIZE = 20
    MERGE_REQUEST_SYNC_BATCH_DELAY = 1.minute.freeze
    BATCH_SIZE = 1_000

    def execute
      if !params[:jira_user]
        return error(s_('JiraConnect|Could not fetch user information from Jira. ' \
                        'Check the permissions in Jira and try again.'), 403)
      elsif !can_administer_jira?
        return error(s_('JiraConnect|The Jira user is not a site or organization administrator. ' \
                        'Check the permissions in Jira and try again.'), 403)
      end

      unless namespace && can?(current_user, :create_jira_connect_subscription, namespace)
        return error(s_('JiraConnect|Cannot find namespace. Make sure you have sufficient permissions.'), 401)
      end

      create_subscription
    end

    private

    def can_administer_jira?
      params[:jira_user]&.jira_admin?
    end

    def create_subscription
      subscription = JiraConnectSubscription.new(installation: jira_connect_installation, namespace: namespace)

      if subscription.save
        create_jira_cloud_integration!
        schedule_sync_project_jobs

        success
      else
        error(subscription.errors.full_messages.join(', '), 422)
      end
    end

    # We must make all GitLab for Jira app integrations active (or inactive in the DestroyService)
    # regardless of whether those integration inherit, or have defined their own custom settings.
    # Unless the group namespace is linked in Jira,
    # the project integrations do not work, even if they are non-inheriting.
    #
    # Using Integration.descendants_from_self_or_ancestors_from we update
    # all integrations of all subgroups and sub projects to be active.
    #
    # We keep their inherit_from_id in tact, as they might have custom service_ids fields.
    # We also still queue a PropagateIntegrationWorker in order to create integrations
    # (the Integration.descendants_from_self_or_ancestors_from only updates existing ones).
    def create_jira_cloud_integration!
      integration = Integration.find_or_initialize_non_project_specific_integration(
        'jira_cloud_app',
        group_id: namespace.id
      )

      return unless integration

      Integrations::JiraCloudApp.transaction do
        integration.inherit_from_id = nil
        integration.activate!

        Integration.descendants_from_self_or_ancestors_from(integration).each_batch(of: BATCH_SIZE) do |records|
          records.update!(active: true)
        end
      end

      # This worker must be queued outside of the PostgreSQL transaction.
      PropagateIntegrationWorker.perform_async(integration.id) if integration.persisted?
    end

    def namespace
      strong_memoize(:namespace) do
        Namespace.find_by_full_path(params[:namespace_path])
      end
    end

    def schedule_sync_project_jobs
      namespace.all_projects.each_batch(of: MERGE_REQUEST_SYNC_BATCH_SIZE) do |projects, index|
        JiraConnect::SyncProjectWorker.bulk_perform_in_with_contexts(
          index * MERGE_REQUEST_SYNC_BATCH_DELAY,
          projects,
          arguments_proc: ->(project) { [project.id, Atlassian::JiraConnect::Client.generate_update_sequence_id] },
          context_proc: ->(project) { { project: project } }
        )
      end
    end
  end
end
