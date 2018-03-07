require 'spec_helper'

describe CreateGithubWebhookWorker do
  include GrapeRouteHelpers::NamedRouteMatcher

  let(:project) do
    create(:project,
           import_source: 'foo/bar',
           import_type: 'github',
           import_data_attributes: { credentials: { user: 'gh_token' } })
  end

  subject do
    described_class.new
  end

  describe '#perform' do
    before do
      project.ensure_external_webhook_token
      project.save
    end

    it 'creates the webhook' do
      expect_any_instance_of(Gitlab::LegacyGithubImport::Client).to receive(:create_hook)
        .with(
          'foo/bar',
          'web',
          {
            url: "http://localhost#{api_v4_projects_mirror_pull_path(id: project.id)}",
            content_type: 'json',
            secret: project.external_webhook_token,
            insecure_ssl: 1
          },
          {
            events: ['push'],
            active: true
          }
        )

      subject.perform(project.id)
    end
  end
end
