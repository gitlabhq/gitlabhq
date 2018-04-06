class CreateGithubWebhookWorker
  include ApplicationWorker
  include GrapeRouteHelpers::NamedRouteMatcher

  attr_reader :project

  def perform(project_id)
    @project = Project.find(project_id)

    create_webhook
  end

  def create_webhook
    client.create_hook(
      project.import_source,
      'web',
      {
        url: webhook_url,
        content_type: 'json',
        secret: webhook_token,
        insecure_ssl: 1
      },
      {
        events: ['push'],
        active: true
      }
    )
  end

  private

  def client
    @client ||= Gitlab::LegacyGithubImport::Client.new(access_token)
  end

  def access_token
    @access_token ||= project.import_data.credentials[:user]
  end

  def webhook_url
    "#{Settings.gitlab.url}#{api_v4_projects_mirror_pull_path(id: project.id)}"
  end

  def webhook_token
    project.ensure_external_webhook_token
    project.save if project.changed?

    project.external_webhook_token
  end
end
