# frozen_string_literal: true

require 'spec_helper'

describe Projects::Import::JiraController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  context 'with anonymous user' do
    before do
      stub_feature_flags(jira_issue_import: true)
    end

    context 'get show' do
      it 'redirects to issues page' do
        get :show, params: { namespace_id: project.namespace, project_id: project }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'post import' do
      it 'redirects to issues page' do
        post :import, params: { namespace_id: project.namespace, project_id: project, jira_project_key: 'Test' }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context 'with logged in user' do
    before do
      sign_in(user)
      project.add_maintainer(user)
    end

    context 'when feature flag not enabled' do
      before do
        stub_feature_flags(jira_issue_import: false)
      end

      context 'get show' do
        it 'redirects to issues page' do
          get :show, params: { namespace_id: project.namespace, project_id: project }

          expect(response).to redirect_to(project_issues_path(project))
        end
      end

      context 'post import' do
        it 'redirects to issues page' do
          post :import, params: { namespace_id: project.namespace, project_id: project, jira_project_key: 'Test' }

          expect(response).to redirect_to(project_issues_path(project))
        end
      end
    end

    context 'when feature flag enabled' do
      before do
        stub_feature_flags(jira_issue_import: true)
      end

      context 'when jira service is enabled for the project' do
        let_it_be(:jira_service) { create(:jira_service, project: project) }

        context 'when running jira import first time' do
          context 'get show' do
            it 'renders show template' do
              allow(JIRA::Resource::Project).to receive(:all).and_return([])
              expect(project.import_state).to be_nil

              get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

              expect(response).to render_template :show
            end
          end

          context 'post import' do
            it 'creates import state' do
              expect(project.import_state).to be_nil

              post :import, params: { namespace_id: project.namespace, project_id: project, jira_project_key: 'Test' }

              project.reload

              jira_project = project.import_data.data.dig('jira', 'projects').first
              expect(project.import_type).to eq 'jira'
              expect(project.import_state.status).to eq 'scheduled'
              expect(jira_project['key']).to eq 'Test'
              expect(response).to redirect_to(project_import_jira_path(project))
            end
          end
        end

        context 'when import state is scheduled' do
          let_it_be(:import_state) { create(:import_state, project: project, status: :scheduled) }

          context 'get show' do
            it 'renders import status' do
              get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

              expect(project.import_state.status).to eq 'scheduled'
              expect(flash.now[:notice]).to eq 'Import scheduled'
            end
          end

          context 'post import' do
            before do
              project.reload
              project.create_import_data(
                data: {
                  'jira': {
                    'projects': [{ 'key': 'Test', scheduled_at: 5.days.ago, scheduled_by: { user_id: user.id, name: user.name } }]
                  }
                }
              )
            end

            it 'uses the existing import data' do
              expect(controller).not_to receive(:schedule_import)

              post :import, params: { namespace_id: project.namespace, project_id: project, jira_project_key: 'New Project' }

              expect(response).to redirect_to(project_import_jira_path(project))
            end
          end
        end

        context 'when jira import ran before' do
          let_it_be(:import_state) { create(:import_state, project: project, status: :finished) }

          context 'get show' do
            it 'renders import status' do
              allow(JIRA::Resource::Project).to receive(:all).and_return([])
              get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

              expect(project.import_state.status).to eq 'finished'
              expect(flash.now[:notice]).to eq 'Import finished'
            end
          end

          context 'post import' do
            before do
              project.reload
              project.create_import_data(
                data: {
                  'jira': {
                    'projects': [{ 'key': 'Test', scheduled_at: 5.days.ago, scheduled_by: { user_id: user.id, name: user.name } }]
                  }
                }
              )
            end

            it 'uses the existing import data' do
              expect(controller).to receive(:schedule_import).and_call_original

              post :import, params: { namespace_id: project.namespace, project_id: project, jira_project_key: 'New Project' }

              project.reload
              expect(project.import_state.status).to eq 'scheduled'
              jira_imported_projects = project.import_data.data.dig('jira', 'projects')
              expect(jira_imported_projects.size).to eq 2
              expect(jira_imported_projects.first['key']).to eq 'Test'
              expect(jira_imported_projects.last['key']).to eq 'New Project'
              expect(response).to redirect_to(project_import_jira_path(project))
            end
          end
        end
      end
    end
  end
end
