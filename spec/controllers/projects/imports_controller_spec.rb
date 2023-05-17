# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportsController, feature_category: :importers do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    sign_in(user) if user
  end

  describe 'GET #show' do
    context 'when user is not authenticated and the project is public' do
      let(:user) { nil }
      let(:project) { create(:project, :public) }

      it 'returns 404 response' do
        get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user has maintainer rights' do
      before do
        project.add_maintainer(user)
      end

      context 'when repository does not exist' do
        it 'renders template' do
          get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

          expect(response).to render_template :show
        end

        it 'sets flash.now if params is present' do
          get :show, params: { namespace_id: project.namespace.to_param, project_id: project, continue: { to: '/', notice_now: 'Started' } }

          expect(flash.now[:notice]).to eq 'Started'
        end
      end

      context 'when repository exists' do
        let(:project) { create(:project_empty_repo, import_url: 'https://github.com/vim/vim.git') }
        let(:import_state) { project.import_state }

        context 'when import is in progress' do
          before do
            import_state.update!(status: :started)
          end

          it 'renders template' do
            get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

            expect(response).to render_template :show
          end

          it 'sets flash.now if params is present' do
            get :show, params: { namespace_id: project.namespace.to_param, project_id: project, continue: { to: '/', notice_now: 'In progress' } }

            expect(flash.now[:notice]).to eq 'In progress'
          end
        end

        context 'when import failed' do
          before do
            import_state.update!(status: :failed)
          end

          it 'redirects to new_namespace_project_import_path' do
            get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

            expect(response).to redirect_to new_project_import_path(project)
          end
        end

        context 'when import finished' do
          before do
            import_state.update!(status: :finished)
          end

          context 'when project is a fork' do
            it 'redirects to namespace_project_path' do
              allow_any_instance_of(Project).to receive(:forked?).and_return(true)

              get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

              expect(flash[:notice]).to eq 'The project was successfully forked.'
              expect(response).to redirect_to project_path(project)
            end
          end

          context 'when project is external' do
            it 'redirects to namespace_project_path' do
              get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

              expect(flash[:notice]).to eq 'The project was successfully imported.'
              expect(response).to redirect_to project_path(project)
            end
          end

          context 'when continue params is present' do
            let(:params) do
              {
                to: project_path(project),
                notice: 'Finished'
              }
            end

            it 'redirects to internal params[:to]' do
              get :show, params: { namespace_id: project.namespace.to_param, project_id: project, continue: params }

              expect(flash[:notice]).to eq params[:notice]
              expect(response).to redirect_to params[:to]
            end

            it 'does not redirect to external params[:to]' do
              params[:to] = "//google.com"

              get :show, params: { namespace_id: project.namespace.to_param, project_id: project, continue: params }
              expect(response).not_to redirect_to params[:to]
            end
          end
        end

        context 'when import never happened' do
          before do
            import_state.update!(status: :none)
          end

          it 'redirects to namespace_project_path' do
            get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

            expect(response).to redirect_to project_path(project)
          end
        end
      end
    end

    context 'when project is in group' do
      let(:project) { create(:project_empty_repo, import_url: 'https://github.com/vim/vim.git', namespace: group) }

      context 'when user has developer access to group and import is in progress' do
        let(:import_state) { project.import_state }

        before do
          group.add_developer(user)
          import_state.update!(status: :started)
        end

        context 'when group prohibits developers to import projects' do
          let(:group) { create(:group, project_creation_level: Gitlab::Access::MAINTAINER_PROJECT_ACCESS) }

          it 'returns 404 response' do
            get :show, params: { namespace_id: project.namespace.to_param, project_id: project }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe 'POST #create' do
    let(:params) { { import_url: 'https://github.com/vim/vim.git', import_url_user: 'user', import_url_password: 'password' } }
    let(:project) { create(:project) }

    before do
      project.add_maintainer(user)
      allow(RepositoryImportWorker).to receive(:perform_async)

      post :create, params: { project: params, namespace_id: project.namespace.to_param, project_id: project }
    end

    it 'sets import_url to the project' do
      expect(project.reload.import_url).to eq('https://user:password@github.com/vim/vim.git')
    end
  end
end
