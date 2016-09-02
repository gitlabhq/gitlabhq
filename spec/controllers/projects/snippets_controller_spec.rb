require 'spec_helper'

describe Projects::SnippetsController do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user)    { create(:user) }
  let(:user2)   { create(:user) }

  before do
    project.team << [user, :master]
    project.team << [user2, :master]
  end

  describe 'GET #index' do
    context 'when the project snippet is private' do
      let!(:project_snippet) { create(:project_snippet, :private, project: project, author: user) }

      context 'when anonymous' do
        it 'does not include the private snippet' do
          get :index, namespace_id: project.namespace.path, project_id: project.path

          expect(assigns(:snippets)).not_to include(project_snippet)
          expect(response).to have_http_status(200)
        end
      end

      context 'when signed in as the author' do
        before { sign_in(user) }

        it 'renders the snippet' do
          get :index, namespace_id: project.namespace.path, project_id: project.path

          expect(assigns(:snippets)).to include(project_snippet)
          expect(response).to have_http_status(200)
        end
      end

      context 'when signed in as a project member' do
        before { sign_in(user2) }

        it 'renders the snippet' do
          get :index, namespace_id: project.namespace.path, project_id: project.path

          expect(assigns(:snippets)).to include(project_snippet)
          expect(response).to have_http_status(200)
        end
      end
    end
  end

  %w[show raw].each do |action|
    describe "GET ##{action}" do
      context 'when the project snippet is private' do
        let(:project_snippet) { create(:project_snippet, :private, project: project, author: user) }

        context 'when anonymous' do
          it 'responds with status 404' do
            get action, namespace_id: project.namespace.path, project_id: project.path, id: project_snippet.to_param

            expect(response).to have_http_status(404)
          end
        end

        context 'when signed in as the author' do
          before { sign_in(user) }

          it 'renders the snippet' do
            get action, namespace_id: project.namespace.path, project_id: project.path, id: project_snippet.to_param

            expect(assigns(:snippet)).to eq(project_snippet)
            expect(response).to have_http_status(200)
          end
        end

        context 'when signed in as a project member' do
          before { sign_in(user2) }

          it 'renders the snippet' do
            get action, namespace_id: project.namespace.path, project_id: project.path, id: project_snippet.to_param

            expect(assigns(:snippet)).to eq(project_snippet)
            expect(response).to have_http_status(200)
          end
        end
      end

      context 'when the project snippet does not exist' do
        context 'when anonymous' do
          it 'responds with status 404' do
            get action, namespace_id: project.namespace.path, project_id: project.path, id: 42

            expect(response).to have_http_status(404)
          end
        end

        context 'when signed in' do
          before { sign_in(user) }

          it 'responds with status 404' do
            get action, namespace_id: project.namespace.path, project_id: project.path, id: 42

            expect(response).to have_http_status(404)
          end
        end
      end
    end
  end
end
