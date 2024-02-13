# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ForksController, feature_category: :source_code_management do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:forked_project) { Projects::ForkService.new(project, user, name: 'Some name').execute[:project] }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
  end

  shared_examples 'forking disabled' do
    let(:project) { create(:project, :private, :repository, :forking_disabled) }

    before do
      project.add_developer(user)
      sign_in(user)
    end

    it 'returns with 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET index' do
    def get_forks(search: nil)
      get :index,
        params: {
          namespace_id: project.namespace,
          project_id: project,
          search: search
        }
    end

    context 'when fork is public' do
      before do
        forked_project.update_attribute(:visibility_level, Project::PUBLIC)
      end

      it 'is visible for non logged in users' do
        get_forks

        expect(assigns[:forks]).to be_present
      end

      it 'forks counts are correct' do
        get_forks

        expect(assigns[:total_forks_count]).to eq(1)
        expect(assigns[:public_forks_count]).to eq(1)
        expect(assigns[:internal_forks_count]).to eq(0)
        expect(assigns[:private_forks_count]).to eq(0)
      end

      context 'after search' do
        it 'forks counts are correct' do
          get_forks(search: 'Non-matching query')

          expect(assigns[:total_forks_count]).to eq(1)
          expect(assigns[:public_forks_count]).to eq(1)
          expect(assigns[:internal_forks_count]).to eq(0)
          expect(assigns[:private_forks_count]).to eq(0)
        end
      end

      context 'when unsupported keys are provided' do
        it 'ignores them' do
          get :index, params: {
            namespace_id: project.namespace,
            project_id: project,
            user: 'unsupported'
          }

          expect(assigns[:forks]).to be_present
        end
      end
    end

    context 'when fork is internal' do
      before do
        forked_project.update!(visibility_level: Project::INTERNAL, group: group)
      end

      it 'forks counts are correct' do
        get_forks

        expect(assigns[:total_forks_count]).to eq(1)
        expect(assigns[:public_forks_count]).to eq(0)
        expect(assigns[:internal_forks_count]).to eq(1)
        expect(assigns[:private_forks_count]).to eq(0)
      end
    end

    context 'when fork is private' do
      before do
        forked_project.update!(visibility_level: Project::PRIVATE, group: group)
      end

      shared_examples 'forks counts' do
        it 'forks counts are correct' do
          get_forks

          expect(assigns[:total_forks_count]).to eq(1)
          expect(assigns[:public_forks_count]).to eq(0)
          expect(assigns[:internal_forks_count]).to eq(0)
          expect(assigns[:private_forks_count]).to eq(1)
        end
      end

      it 'is not visible for non logged in users' do
        get_forks

        expect(assigns[:forks]).to be_blank
      end

      include_examples 'forks counts'

      context 'when user is logged in' do
        before do
          sign_in(project.creator)
        end

        context 'when user is not a Project member neither a group member' do
          it 'does not see the Project listed' do
            get_forks

            expect(assigns[:forks]).to be_blank
          end
        end

        context 'when user is a member of the Project' do
          before do
            forked_project.add_developer(project.creator)
          end

          it 'sees the project listed' do
            get_forks

            expect(assigns[:forks]).to be_present
          end

          include_examples 'forks counts'
        end

        context 'when user is a member of the Group' do
          before do
            forked_project.group.add_developer(project.creator)
          end

          it 'sees the project listed' do
            get_forks

            expect(assigns[:forks]).to be_present
          end

          include_examples 'forks counts'
        end
      end
    end
  end

  describe 'GET new' do
    let(:format) { :html }

    subject(:do_request) do
      get :new, format: format, params: { namespace_id: project.namespace, project_id: project }
    end

    context 'when user is signed in' do
      before do
        sign_in(user)
      end

      it 'responds with status 200' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when JSON is requested' do
        let(:format) { :json }

        it 'responds with user namespace + groups' do
          do_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['namespaces'].length).to eq(2)
          expect(json_response['namespaces'][0]['id']).to eq(user.namespace.id)
          expect(json_response['namespaces'][1]['id']).to eq(group.id)
        end

        context 'N+1 queries' do
          before do
            create(:fork_network, root_project: project)
          end

          it 'avoids N+1 queries' do
            do_request = -> { get :new, format: format, params: { namespace_id: project.namespace, project_id: project } }

            # warm up
            do_request.call

            control = ActiveRecord::QueryRecorder.new { do_request.call }

            create(:group, :public).add_owner(user)

            expect { do_request.call }.not_to exceed_query_limit(control)
          end
        end
      end
    end

    context 'when user is not signed in' do
      it 'redirects to the sign-in page' do
        sign_out(user)

        subject

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it_behaves_like 'forking disabled'
  end

  describe 'POST create' do
    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        namespace_key: user.namespace.id
      }
    end

    let(:created_project) do
      Namespace
        .find_by_id(params[:namespace_key])
        .projects
        .find_by_path(params.fetch(:path, project.path))
    end

    subject do
      post :create, params: params
    end

    context 'when user is signed in' do
      before do
        sign_in(user)
      end

      it 'responds with status 302' do
        subject

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_import_path(user.namespace, project))
      end

      context 'when target namespace is not valid for forking' do
        let(:params) { super().merge(namespace_key: another_group.id) }
        let(:another_group) { create :group }

        it 'responds with :not_found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when fork already exists' do
        before do
          forked_project
        end

        it 'responds with status 302' do
          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(namespace_project_import_path(user.namespace, project))
        end
      end

      context 'when fork process fails' do
        before do
          allow_next_instance_of(Projects::ForkService) do |instance|
            allow(instance).to receive(:execute).and_return(ServiceResponse.error(message: 'Error'))
          end
        end

        it 'responds with an error page' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:error)
        end
      end

      context 'continue params' do
        let(:params) do
          {
            namespace_id: project.namespace,
            project_id: project,
            namespace_key: user.namespace.id,
            continue: continue_params
          }
        end

        let(:continue_params) do
          {
            to: '/-/ide/project/path',
            notice: 'message'
          }
        end

        it 'passes continue params to the redirect' do
          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(namespace_project_import_path(user.namespace, project, continue: continue_params))
        end
      end

      context 'custom attributes set' do
        let(:params) { super().merge(path: 'something_custom', name: 'Something Custom', description: 'Something Custom', visibility: 'private') }

        it 'creates a project with custom values' do
          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(namespace_project_import_path(user.namespace, params[:path]))
          expect(created_project.path).to eq(params[:path])
          expect(created_project.name).to eq(params[:name])
          expect(created_project.description).to eq(params[:description])
          expect(created_project.visibility).to eq(params[:visibility])
        end
      end
    end

    context 'when user is not signed in' do
      it 'redirects to the sign-in page' do
        sign_out(user)

        subject

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it_behaves_like 'forking disabled'
  end
end
