# frozen_string_literal: true

require 'spec_helper'

describe Projects::Import::JiraController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:jira_project_key) { 'Test' }

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
        post :import, params: { namespace_id: project.namespace, project_id: project, jira_project_key: jira_project_key }

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
          post :import, params: { namespace_id: project.namespace, project_id: project, jira_project_key: jira_project_key }

          expect(response).to redirect_to(project_issues_path(project))
        end
      end
    end

    context 'when feature flag enabled' do
      before do
        stub_feature_flags(jira_issue_import: true)
        stub_feature_flags(jira_issue_import_vue: false)
      end

      context 'when Jira service is enabled for the project' do
        let_it_be(:jira_service) { create(:jira_service, project: project) }

        context 'when user is developer' do
          let_it_be(:dev) { create(:user) }

          before do
            sign_in(dev)
            project.add_developer(dev)
          end

          context 'get show' do
            before do
              get :show, params: { namespace_id: project.namespace.to_param, project_id: project }
            end

            it 'does not query Jira service' do
              expect(project).not_to receive(:jira_service)
            end

            it 'renders show template' do
              expect(response).to render_template(:show)
              expect(assigns(:jira_projects)).not_to be_present
            end
          end

          context 'post import' do
            it 'returns 404' do
              post :import, params: { namespace_id: project.namespace, project_id: project, jira_project_key: jira_project_key }

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end

        context 'when issues disabled' do
          let_it_be(:disabled_issues_project) { create(:project, :public, :issues_disabled) }

          context 'get show' do
            it 'returs 404' do
              get :show, params: { namespace_id: project.namespace.to_param, project_id: disabled_issues_project }

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context 'post import' do
            it 'returs 404' do
              post :import, params: { namespace_id: disabled_issues_project.namespace, project_id: disabled_issues_project, jira_project_key: jira_project_key }

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end

        context 'when running Jira import first time' do
          context 'get show' do
            before do
              allow(JIRA::Resource::Project).to receive(:all).and_return(jira_projects)

              expect(project.jira_imports).to be_empty

              get :show, params: { namespace_id: project.namespace.to_param, project_id: project }
            end

            context 'when no projects have been retrieved from Jira' do
              let(:jira_projects) { [] }

              it 'render an error message' do
                expect(flash[:alert]).to eq('No projects have been returned from Jira. Please check your Jira configuration.')
                expect(response).to render_template(:show)
              end
            end

            context 'when projects retrieved from Jira' do
              let(:jira_projects) { [double(name: 'FOO project', key: 'FOO')] }

              it 'renders show template' do
                expect(response).to render_template(:show)
              end
            end
          end

          context 'post import' do
            context 'when Jira project key is empty' do
              it 'redirects back to show with an error' do
                post :import, params: { namespace_id: project.namespace, project_id: project, jira_project_key: '' }

                expect(response).to redirect_to(project_import_jira_path(project))
                expect(flash[:alert]).to eq('No Jira project key has been provided.')
              end
            end

            context 'when everything is ok' do
              it 'creates import state' do
                expect(project.latest_jira_import).to be_nil

                post :import, params: { namespace_id: project.namespace, project_id: project, jira_project_key: jira_project_key }

                project.reload

                jira_import = project.latest_jira_import
                expect(project.import_type).to eq 'jira'
                expect(jira_import.status).to eq 'scheduled'
                expect(jira_import.jira_project_key).to eq jira_project_key
                expect(response).to redirect_to(project_import_jira_path(project))
              end
            end
          end
        end

        context 'when import state is scheduled' do
          let_it_be(:jira_import_state) { create(:jira_import_state, :scheduled, project: project) }

          context 'get show' do
            it 'renders import status' do
              get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

              jira_import = project.latest_jira_import
              expect(jira_import.status).to eq 'scheduled'
              expect(flash.now[:notice]).to eq 'Import scheduled'
            end
          end

          context 'post import' do
            it 'uses the existing import data' do
              post :import, params: { namespace_id: project.namespace, project_id: project, jira_project_key: 'New Project' }

              expect(flash[:notice]).to eq('Jira import is already running.')
              expect(response).to redirect_to(project_import_jira_path(project))
            end
          end
        end

        context 'when Jira import ran before' do
          let_it_be(:jira_import_state) { create(:jira_import_state, :finished, project: project, jira_project_key: jira_project_key) }

          context 'get show' do
            it 'renders import status' do
              allow(JIRA::Resource::Project).to receive(:all).and_return([])
              get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

              expect(project.latest_jira_import.status).to eq 'finished'
              expect(flash.now[:notice]).to eq 'Import finished'
            end
          end

          context 'post import' do
            it 'uses the existing import data' do
              post :import, params: { namespace_id: project.namespace, project_id: project, jira_project_key: 'New Project' }

              project.reload
              expect(project.latest_jira_import.status).to eq 'scheduled'
              expect(project.jira_imports.size).to eq 2
              expect(project.jira_imports.first.jira_project_key).to eq jira_project_key
              expect(project.jira_imports.last.jira_project_key).to eq 'New Project'
              expect(response).to redirect_to(project_import_jira_path(project))
            end
          end
        end
      end
    end
  end
end
