# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Import::JiraController do
  include JiraIntegrationHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:jira_project_key) { 'Test' }

  def ensure_correct_config
    sign_in(user)
    project.add_maintainer(user)
    stub_jira_integration_test
  end

  shared_examples 'redirect with error' do |error|
    it 'redirects to project issues path' do
      subject

      expect(response).to redirect_to(project_issues_path(project))
    end

    it 'renders a correct error' do
      subject

      expect(flash[:notice]).to eq(error)
    end
  end

  shared_examples 'template with no message' do
    it 'does not set any message' do
      subject

      expect(flash).to be_empty
    end

    it 'renders show template' do
      subject

      expect(response).to render_template(template)
    end
  end

  shared_examples 'users without permissions' do
    context 'with anonymous user' do
      it 'redirects to new user page' do
        subject

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when loged user is a developer' do
      before do
        create(:jira_integration, project: project)
        stub_jira_integration_test

        sign_in(user)
        project.add_developer(user)
      end

      it_behaves_like 'redirect with error', 'You do not have permissions to run the import.'
    end
  end

  describe 'GET #show' do
    let(:template) { 'show' }

    subject { get :show, params: { namespace_id: project.namespace, project_id: project } }

    it_behaves_like 'users without permissions'

    context 'jira integration configuration' do
      before do
        sign_in(user)
        project.add_maintainer(user)
      end

      context 'when Jira service is not enabled for the project' do
        it 'does not query Jira service' do
          expect(project).not_to receive(:jira_integration)
        end

        it_behaves_like 'template with no message'
      end

      context 'when Jira service is not configured correctly for the project' do
        let_it_be(:jira_integration) { create(:jira_integration, project: project) }

        before do
          WebMock.stub_request(:get, 'https://jira.example.com/rest/api/2/serverInfo')
            .to_raise(JIRA::HTTPError.new(double(message: 'Some failure.')))
        end

        it_behaves_like 'template with no message'
      end
    end
  end
end
