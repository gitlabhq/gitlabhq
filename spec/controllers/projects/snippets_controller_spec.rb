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
          namespace_id: project.namespace,
          project_id: project, page: (last_page + 1).to_param

        expect(response).to redirect_to(namespace_project_snippets_path(page: last_page))
      end

      it 'redirects to specified page' do
        get :index,
          namespace_id: project.namespace,
          project_id: project, page: last_page.to_param

        expect(assigns(:snippets).current_page).to eq(last_page)
        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'when the project snippet is private' do
      let!(:project_snippet) { create(:project_snippet, :private, project: project, author: user) }

      context 'when anonymous' do
        it 'does not include the private snippet' do
          get :index, namespace_id: project.namespace, project_id: project

          expect(assigns(:snippets)).not_to include(project_snippet)
          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'when signed in as the author' do
        before do
          sign_in(user)
        end

        it 'renders the snippet' do
          get :index, namespace_id: project.namespace, project_id: project

          expect(assigns(:snippets)).to include(project_snippet)
          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'when signed in as a project member' do
        before do
          sign_in(user2)
        end

        it 'renders the snippet' do
          get :index, namespace_id: project.namespace, project_id: project

          expect(assigns(:snippets)).to include(project_snippet)
          expect(response).to have_gitlab_http_status(200)
        end
      end
    end
  end

  describe 'POST #create' do
    def create_snippet(project, snippet_params = {}, additional_params = {})
      sign_in(user)

      project.add_developer(user)

      post :create, {
        namespace_id: project.namespace.to_param,
        project_id: project,
        project_snippet: { title: 'Title', content: 'Content', description: 'Description' }.merge(snippet_params)
      }.merge(additional_params)

      Snippet.last
    end

    it 'creates the snippet correctly' do
      snippet = create_snippet(project, visibility_level: Snippet::PRIVATE)

      expect(snippet.title).to eq('Title')
      expect(snippet.content).to eq('Content')
      expect(snippet.description).to eq('Description')
    end

    context 'when the snippet is spam' do
      before do
        allow_any_instance_of(AkismetService).to receive(:spam?).and_return(true)
      end

      context 'when the snippet is private' do
        it 'creates the snippet' do
          expect { create_snippet(project, visibility_level: Snippet::PRIVATE) }
            .to change { Snippet.count }.by(1)
        end
      end

      context 'when the snippet is public' do
        it 'rejects the shippet' do
          expect { create_snippet(project, visibility_level: Snippet::PUBLIC) }
            .not_to change { Snippet.count }
          expect(response).to render_template(:new)
        end

        it 'creates a spam log' do
          expect { create_snippet(project, visibility_level: Snippet::PUBLIC) }
            .to change { SpamLog.count }.by(1)
        end

        it 'renders :new with recaptcha disabled' do
          stub_application_setting(recaptcha_enabled: false)

          create_snippet(project, visibility_level: Snippet::PUBLIC)

          expect(response).to render_template(:new)
        end

        context 'recaptcha enabled' do
          before do
            stub_application_setting(recaptcha_enabled: true)
          end

          it 'renders :verify with recaptcha enabled' do
            create_snippet(project, visibility_level: Snippet::PUBLIC)

            expect(response).to render_template(:verify)
          end

          it 'renders snippet page when recaptcha verified' do
            spammy_title = 'Whatever'

            spam_logs = create_list(:spam_log, 2, user: user, title: spammy_title)
            create_snippet(project,
                           { visibility_level: Snippet::PUBLIC },
                           { spam_log_id: spam_logs.last.id,
                             recaptcha_verification: true })

            expect(response).to redirect_to(project_snippet_path(project, Snippet.last))
          end
        end
      end
    end
  end

  describe 'PUT #update' do
    let(:project) { create :project, :public }
    let(:snippet) { create :project_snippet, author: user, project: project, visibility_level: visibility_level }

    def update_snippet(snippet_params = {}, additional_params = {})
      sign_in(user)

      project.add_developer(user)

      put :update, {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: snippet.id,
        project_snippet: { title: 'Title', content: 'Content' }.merge(snippet_params)
      }.merge(additional_params)

      snippet.reload
    end

    context 'when the snippet is spam' do
      before do
        allow_any_instance_of(AkismetService).to receive(:spam?).and_return(true)
      end

      context 'when the snippet is private' do
        let(:visibility_level) { Snippet::PRIVATE }

        it 'updates the snippet' do
          expect { update_snippet(title: 'Foo') }
            .to change { snippet.reload.title }.to('Foo')
        end
      end

      context 'when the snippet is public' do
        let(:visibility_level) { Snippet::PUBLIC }

        it 'rejects the shippet' do
          expect { update_snippet(title: 'Foo') }
            .not_to change { snippet.reload.title }
        end

        it 'creates a spam log' do
          expect { update_snippet(title: 'Foo') }
            .to change { SpamLog.count }.by(1)
        end

        it 'renders :edit with recaptcha disabled' do
          stub_application_setting(recaptcha_enabled: false)

          update_snippet(title: 'Foo')

          expect(response).to render_template(:edit)
        end

        context 'recaptcha enabled' do
          before do
            stub_application_setting(recaptcha_enabled: true)
          end

          it 'renders :verify with recaptcha enabled' do
            update_snippet(title: 'Foo')

            expect(response).to render_template(:verify)
          end

          it 'renders snippet page when recaptcha verified' do
            spammy_title = 'Whatever'

            spam_logs = create_list(:spam_log, 2, user: user, title: spammy_title)
            snippet = update_snippet({ title: spammy_title },
                                     { spam_log_id: spam_logs.last.id,
                                       recaptcha_verification: true })

            expect(response).to redirect_to(project_snippet_path(project, snippet))
          end
        end
      end

      context 'when the private snippet is made public' do
        let(:visibility_level) { Snippet::PRIVATE }

        it 'rejects the shippet' do
          expect { update_snippet(title: 'Foo', visibility_level: Snippet::PUBLIC) }
            .not_to change { snippet.reload.title }
        end

        it 'creates a spam log' do
          expect { update_snippet(title: 'Foo', visibility_level: Snippet::PUBLIC) }
            .to change { SpamLog.count }.by(1)
        end

        it 'renders :edit with recaptcha disabled' do
          stub_application_setting(recaptcha_enabled: false)

          update_snippet(title: 'Foo', visibility_level: Snippet::PUBLIC)

          expect(response).to render_template(:edit)
        end

        context 'recaptcha enabled' do
          before do
            stub_application_setting(recaptcha_enabled: true)
          end

          it 'renders :verify with recaptcha enabled' do
            update_snippet(title: 'Foo', visibility_level: Snippet::PUBLIC)

            expect(response).to render_template(:verify)
          end

          it 'renders snippet page when recaptcha verified' do
            spammy_title = 'Whatever'

            spam_logs = create_list(:spam_log, 2, user: user, title: spammy_title)
            snippet = update_snippet({ title: spammy_title, visibility_level: Snippet::PUBLIC },
                                     { spam_log_id: spam_logs.last.id,
                                       recaptcha_verification: true })

            expect(response).to redirect_to(project_snippet_path(project, snippet))
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
           namespace_id: project.namespace,
           project_id: project,
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
            get action, namespace_id: project.namespace, project_id: project, id: project_snippet.to_param

            expect(response).to have_gitlab_http_status(404)
          end
        end

        context 'when signed in as the author' do
          before do
            sign_in(user)
          end

          it 'renders the snippet' do
            get action, namespace_id: project.namespace, project_id: project, id: project_snippet.to_param

            expect(assigns(:snippet)).to eq(project_snippet)
            expect(response).to have_gitlab_http_status(200)
          end
        end

        context 'when signed in as a project member' do
          before do
            sign_in(user2)
          end

          it 'renders the snippet' do
            get action, namespace_id: project.namespace, project_id: project, id: project_snippet.to_param

            expect(assigns(:snippet)).to eq(project_snippet)
            expect(response).to have_gitlab_http_status(200)
          end
        end
      end

      context 'when the project snippet does not exist' do
        context 'when anonymous' do
          it 'responds with status 404' do
            get action, namespace_id: project.namespace, project_id: project, id: 42

            expect(response).to have_gitlab_http_status(404)
          end
        end

        context 'when signed in' do
          before do
            sign_in(user)
          end

          it 'responds with status 404' do
            get action, namespace_id: project.namespace, project_id: project, id: 42

            expect(response).to have_gitlab_http_status(404)
          end
        end
      end
    end
  end

  describe 'GET #raw' do
    let(:project_snippet) do
      create(
        :project_snippet, :public,
        project: project,
        author: user,
        content: "first line\r\nsecond line\r\nthird line"
      )
    end

    context 'CRLF line ending' do
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: project_snippet.to_param
        }
      end

      it 'returns LF line endings by default' do
        get :raw, params

        expect(response.body).to eq("first line\nsecond line\nthird line")
      end

      it 'does not convert line endings when parameter present' do
        get :raw, params.merge(line_ending: :raw)

        expect(response.body).to eq("first line\r\nsecond line\r\nthird line")
      end
    end
  end
end
