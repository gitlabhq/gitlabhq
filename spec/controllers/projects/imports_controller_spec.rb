require 'spec_helper'

describe Projects::ImportsController do
  let(:user) { create(:user) }

  describe 'GET #show' do
    context 'when repository does not exists' do
      let(:project) { create(:project) }

      before do
        sign_in(user)
        project.add_master(user)
      end

      it 'renders template' do
        get :show, namespace_id: project.namespace.to_param, project_id: project

        expect(response).to render_template :show
      end

      it 'sets flash.now if params is present' do
        get :show, namespace_id: project.namespace.to_param, project_id: project, continue: { to: '/', notice_now: 'Started' }

        expect(flash.now[:notice]).to eq 'Started'
      end
    end

    context 'when repository exists' do
      let(:project) { create(:project_empty_repo, import_url: 'https://github.com/vim/vim.git') }

      before do
        sign_in(user)
        project.add_master(user)
      end

      context 'when import is in progress' do
        before do
          project.update_attribute(:import_status, :started)
        end

        it 'renders template' do
          get :show, namespace_id: project.namespace.to_param, project_id: project

          expect(response).to render_template :show
        end

        it 'sets flash.now if params is present' do
          get :show, namespace_id: project.namespace.to_param, project_id: project, continue: { to: '/', notice_now: 'In progress' }

          expect(flash.now[:notice]).to eq 'In progress'
        end
      end

      context 'when import failed' do
        before do
          project.update_attribute(:import_status, :failed)
        end

        it 'redirects to new_namespace_project_import_path' do
          get :show, namespace_id: project.namespace.to_param, project_id: project

          expect(response).to redirect_to new_project_import_path(project)
        end
      end

      context 'when import finished' do
        before do
          project.update_attribute(:import_status, :finished)
        end

        context 'when project is a fork' do
          it 'redirects to namespace_project_path' do
            allow_any_instance_of(Project).to receive(:forked?).and_return(true)

            get :show, namespace_id: project.namespace.to_param, project_id: project

            expect(flash[:notice]).to eq 'The project was successfully forked.'
            expect(response).to redirect_to project_path(project)
          end
        end

        context 'when project is external' do
          it 'redirects to namespace_project_path' do
            get :show, namespace_id: project.namespace.to_param, project_id: project

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
            get :show, namespace_id: project.namespace.to_param, project_id: project, continue: params

            expect(flash[:notice]).to eq params[:notice]
            expect(response).to redirect_to params[:to]
          end

          it 'does not redirect to external params[:to]' do
            params[:to] = "//google.com"

            get :show, namespace_id: project.namespace.to_param, project_id: project, continue: params
            expect(response).not_to redirect_to params[:to]
          end
        end
      end

      context 'when import never happened' do
        before do
          project.update_attribute(:import_status, :none)
        end

        it 'redirects to namespace_project_path' do
          get :show, namespace_id: project.namespace.to_param, project_id: project

          expect(response).to redirect_to project_path(project)
        end
      end
    end
  end
end
