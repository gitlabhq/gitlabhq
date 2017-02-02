require 'spec_helper'

describe Projects::SnippetsController do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user)    { create(:user) }
  let(:user2)   { create(:user) }

  before do
    project.add_master(user)
    project.add_master(user2)
  end

  describe 'GET #index' do
    context 'when page param' do
      let(:last_page) { project.snippets.page().total_pages }
      let!(:project_snippet) { create(:project_snippet, :public, project: project, author: user) }

      it 'redirects to last_page if page number is larger than number of pages' do
        get :index,
          namespace_id: project.namespace.path,
          project_id: project.path, page: (last_page + 1).to_param

        expect(response).to redirect_to(namespace_project_snippets_path(page: last_page))
      end

      it 'redirects to specified page' do
        get :index,
          namespace_id: project.namespace.path,
          project_id: project.path, page: last_page.to_param

        expect(assigns(:snippets).current_page).to eq(last_page)
        expect(response).to have_http_status(200)
      end
    end

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

  describe 'POST #create' do
    def create_snippet(project, snippet_params = {})
      sign_in(user)

      project.add_developer(user)

      post :create, {
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        project_snippet: { title: 'Title', content: 'Content' }.merge(snippet_params)
      }
    end

    context 'when the snippet is spam' do
      before do
        allow_any_instance_of(AkismetService).to receive(:is_spam?).and_return(true)
      end

      context 'when the project is private' do
        let(:private_project) { create(:project_empty_repo, :private) }

        context 'when the snippet is public' do
          it 'creates the snippet' do
            expect { create_snippet(private_project, visibility_level: Snippet::PUBLIC) }.
              to change { Snippet.count }.by(1)
          end
        end
      end

      context 'when the project is public' do
        context 'when the snippet is private' do
          it 'creates the snippet' do
            expect { create_snippet(project, visibility_level: Snippet::PRIVATE) }.
              to change { Snippet.count }.by(1)
          end
        end

        context 'when the snippet is public' do
          it 'rejects the shippet' do
            expect { create_snippet(project, visibility_level: Snippet::PUBLIC) }.
              not_to change { Snippet.count }
            expect(response).to render_template(:new)
          end

          it 'creates a spam log' do
            expect { create_snippet(project, visibility_level: Snippet::PUBLIC) }.
              to change { SpamLog.count }.by(1)
          end
        end
      end
    end
  end

  describe 'POST #mark_as_spam' do
    let(:snippet) { create(:project_snippet, :private, project: project, author: user) }

    before do
      allow_any_instance_of(AkismetService).to receive_messages(submit_spam: true)
      stub_application_setting(akismet_enabled: true)
    end

    def mark_as_spam
      admin = create(:admin)
      create(:user_agent_detail, subject: snippet)
      project.add_master(admin)
      sign_in(admin)

      post :mark_as_spam,
           namespace_id: project.namespace.path,
           project_id: project.path,
           id: snippet.id
    end

    it 'updates the snippet' do
      mark_as_spam

      expect(snippet.reload).not_to be_submittable_as_spam
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
