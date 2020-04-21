# frozen_string_literal: true

require 'spec_helper'

describe Projects::SnippetsController do
  include Gitlab::Routing

  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let(:project) { create(:project_empty_repo, :public) }

  before do
    project.add_maintainer(user)
    project.add_maintainer(user2)
  end

  describe 'GET #index' do
    it_behaves_like 'paginated collection' do
      let(:collection) { project.snippets }
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project
        }
      end

      before do
        create(:project_snippet, :public, project: project, author: user)
      end
    end

    it 'fetches snippet counts via the snippet count service' do
      service = double(:count_service, execute: {})
      expect(Snippets::CountService)
        .to receive(:new).with(nil, project: project)
        .and_return(service)

      get :index, params: { namespace_id: project.namespace, project_id: project }
    end

    context 'when the project snippet is private' do
      let!(:project_snippet) { create(:project_snippet, :private, project: project, author: user) }

      context 'when anonymous' do
        it 'does not include the private snippet' do
          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(assigns(:snippets)).not_to include(project_snippet)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when signed in as the author' do
        before do
          sign_in(user)
        end

        it 'renders the snippet' do
          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(assigns(:snippets)).to include(project_snippet)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when signed in as a project member' do
        before do
          sign_in(user2)
        end

        it 'renders the snippet' do
          get :index, params: { namespace_id: project.namespace, project_id: project }

          expect(assigns(:snippets)).to include(project_snippet)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'POST #create' do
    def create_snippet(project, snippet_params = {}, additional_params = {})
      sign_in(user)

      project.add_developer(user)

      post :create, params: {
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
        allow_next_instance_of(Spam::AkismetService) do |instance|
          allow(instance).to receive(:spam?).and_return(true)
        end
      end

      context 'when the snippet is private' do
        it 'creates the snippet' do
          expect { create_snippet(project, visibility_level: Snippet::PRIVATE) }
            .to change { Snippet.count }.by(1)
        end
      end

      context 'when the snippet is public' do
        it 'rejects the snippet' do
          expect { create_snippet(project, visibility_level: Snippet::PUBLIC) }
            .not_to change { Snippet.count }
          expect(response).to render_template(:new)
        end

        it 'creates a spam log' do
          expect { create_snippet(project, visibility_level: Snippet::PUBLIC) }
            .to log_spam(title: 'Title', user_id: user.id, noteable_type: 'ProjectSnippet')
        end

        it 'renders :new with reCAPTCHA disabled' do
          stub_application_setting(recaptcha_enabled: false)

          create_snippet(project, visibility_level: Snippet::PUBLIC)

          expect(response).to render_template(:new)
        end

        context 'reCAPTCHA enabled' do
          before do
            stub_application_setting(recaptcha_enabled: true)
          end

          it 'renders :verify with reCAPTCHA enabled' do
            create_snippet(project, visibility_level: Snippet::PUBLIC)

            expect(response).to render_template(:verify)
          end

          it 'renders snippet page when reCAPTCHA verified' do
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
    let(:visibility_level) { Snippet::PUBLIC }
    let(:snippet) { create :project_snippet, author: user, project: project, visibility_level: visibility_level }

    def update_snippet(snippet_params = {}, additional_params = {})
      sign_in(user)

      project.add_developer(user)

      put :update, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: snippet,
        project_snippet: { title: 'Title', content: 'Content' }.merge(snippet_params)
      }.merge(additional_params)

      snippet.reload
    end

    it_behaves_like 'updating snippet checks blob is binary' do
      let_it_be(:title) { 'Foo' }
      let(:params) do
        {
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: snippet.id,
          project_snippet: { title: title }
        }
      end

      subject { put :update, params: params }
    end

    context 'when the snippet is spam' do
      before do
        allow_next_instance_of(Spam::AkismetService) do |instance|
          allow(instance).to receive(:spam?).and_return(true)
        end
      end

      context 'when the snippet is private' do
        let(:visibility_level) { Snippet::PRIVATE }

        it 'updates the snippet' do
          expect { update_snippet(title: 'Foo') }
            .to change { snippet.reload.title }.to('Foo')
        end
      end

      context 'when the snippet is public' do
        it 'rejects the snippet' do
          expect { update_snippet(title: 'Foo') }
            .not_to change { snippet.reload.title }
        end

        it 'creates a spam log' do
          expect { update_snippet(title: 'Foo') }
            .to log_spam(title: 'Foo', user_id: user.id, noteable_type: 'ProjectSnippet')
        end

        it 'renders :edit with reCAPTCHA disabled' do
          stub_application_setting(recaptcha_enabled: false)

          update_snippet(title: 'Foo')

          expect(response).to render_template(:edit)
        end

        context 'reCAPTCHA enabled' do
          before do
            stub_application_setting(recaptcha_enabled: true)
          end

          it 'renders :verify with reCAPTCHA enabled' do
            update_snippet(title: 'Foo')

            expect(response).to render_template(:verify)
          end

          it 'renders snippet page when reCAPTCHA verified' do
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

        it 'rejects the snippet' do
          expect { update_snippet(title: 'Foo', visibility_level: Snippet::PUBLIC) }
            .not_to change { snippet.reload.title }
        end

        it 'creates a spam log' do
          expect { update_snippet(title: 'Foo', visibility_level: Snippet::PUBLIC) }
            .to log_spam(title: 'Foo', user_id: user.id, noteable_type: 'ProjectSnippet')
        end

        it 'renders :edit with reCAPTCHA disabled' do
          stub_application_setting(recaptcha_enabled: false)

          update_snippet(title: 'Foo', visibility_level: Snippet::PUBLIC)

          expect(response).to render_template(:edit)
        end

        context 'reCAPTCHA enabled' do
          before do
            stub_application_setting(recaptcha_enabled: true)
          end

          it 'renders :verify' do
            update_snippet(title: 'Foo', visibility_level: Snippet::PUBLIC)

            expect(response).to render_template(:verify)
          end

          it 'renders snippet page' do
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
      allow_next_instance_of(Spam::AkismetService) do |instance|
        allow(instance).to receive_messages(submit_spam: true)
      end
      stub_application_setting(akismet_enabled: true)
    end

    def mark_as_spam
      admin = create(:admin)
      create(:user_agent_detail, subject: snippet)
      project.add_maintainer(admin)
      sign_in(admin)

      post :mark_as_spam,
           params: {
             namespace_id: project.namespace,
             project_id: project,
             id: snippet.id
           }
    end

    it 'updates the snippet' do
      mark_as_spam

      expect(snippet.reload).not_to be_submittable_as_spam
    end
  end

  shared_examples 'successful response' do
    it 'renders the snippet' do
      subject

      expect(assigns(:snippet)).to eq(project_snippet)
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'renders the blob from the repository' do
      subject

      expect(assigns(:blob)).to eq(project_snippet.blobs.first)
    end

    context 'when feature flag version_snippets is disabled' do
      before do
        stub_feature_flags(version_snippets: false)
      end

      it 'returns the snippet database content' do
        subject

        blob = assigns(:blob)

        expect(blob.data).to eq(project_snippet.content)
      end
    end
  end

  %w[show raw].each do |action|
    describe "GET ##{action}" do
      context 'when the project snippet is private' do
        let(:project_snippet) { create(:project_snippet, :private, :repository, project: project, author: user) }

        subject { get action, params: { namespace_id: project.namespace, project_id: project, id: project_snippet.to_param } }

        context 'when anonymous' do
          it 'responds with status 404' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when signed in as the author' do
          before do
            sign_in(user)
          end

          it_behaves_like 'successful response'
        end

        context 'when signed in as a project member' do
          before do
            sign_in(user2)
          end

          it_behaves_like 'successful response'
        end
      end

      context 'when the project snippet does not exist' do
        subject { get action, params: { namespace_id: project.namespace, project_id: project, id: 42 } }

        context 'when anonymous' do
          it 'responds with status 404' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when signed in' do
          before do
            sign_in(user)
          end

          it 'responds with status 404' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe "GET #show for embeddable content" do
    let(:project_snippet) { create(:project_snippet, :repository, snippet_permission, project: project, author: user) }

    before do
      sign_in(user)
    end

    subject { get :show, params: { namespace_id: project.namespace, project_id: project, id: project_snippet.to_param }, format: :js }

    context 'when snippet is private' do
      let(:snippet_permission) { :private }

      it 'responds with status 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when snippet is public' do
      let(:snippet_permission) { :public }

      it_behaves_like 'successful response'
    end

    context 'when the project is private' do
      let(:project) { create(:project_empty_repo, :private) }

      context 'when snippet is public' do
        let(:project_snippet) { create(:project_snippet, :public, project: project, author: user) }

        it 'responds with status 404' do
          subject

          expect(assigns(:snippet)).to eq(project_snippet)
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET #raw' do
    let(:inline) { nil }
    let(:line_ending) { nil }
    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: project_snippet.to_param,
        inline: inline,
        line_ending: line_ending
      }
    end

    subject { get :raw, params: params }

    context 'when repository is empty' do
      let(:content) { "first line\r\nsecond line\r\nthird line" }
      let(:formatted_content) { content.gsub(/\r\n/, "\n") }
      let(:project_snippet) do
        create(
          :project_snippet, :public, :empty_repo,
          project: project,
          author: user,
          content: content
        )
      end

      context 'CRLF line ending' do
        before do
          allow_next_instance_of(Blob) do |instance|
            allow(instance).to receive(:data).and_return(content)
          end
        end

        it 'returns LF line endings by default' do
          subject

          expect(response.body).to eq(formatted_content)
        end

        context 'when line_ending parameter present' do
          let(:line_ending) { :raw }

          it 'does not convert line endings' do
            subject

            expect(response.body).to eq(content)
          end
        end
      end
    end

    context 'when repository is not empty' do
      let(:project_snippet) do
        create(
          :project_snippet, :public, :repository,
          project: project,
          author: user
        )
      end

      it 'sends the blob' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
        expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq 'true'
      end

      it_behaves_like 'project cache control headers'
      it_behaves_like 'content disposition headers'
    end
  end

  describe 'DELETE #destroy' do
    let!(:snippet) { create(:project_snippet, :private, project: project, author: user) }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: snippet.to_param
      }
    end

    context 'when current user has ability to destroy the snippet' do
      before do
        sign_in(user)
      end

      it 'removes the snippet' do
        delete :destroy, params: params

        expect { snippet.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'when snippet is succesfuly destroyed' do
        it 'redirects to the project snippets page' do
          delete :destroy, params: params

          expect(response).to redirect_to(project_snippets_path(project))
        end
      end

      context 'when snippet is not destroyed' do
        before do
          allow(snippet).to receive(:destroy).and_return(false)
          controller.instance_variable_set(:@snippet, snippet)
        end

        it 'renders the snippet page with errors' do
          delete :destroy, params: params

          expect(flash[:alert]).to eq('Failed to remove snippet.')
          expect(response).to redirect_to(project_snippet_path(project, snippet))
        end
      end
    end

    context 'when current_user does not have ability to destroy the snippet' do
      let(:another_user) { create(:user) }

      before do
        sign_in(another_user)
      end

      it 'responds with status 404' do
        delete :destroy, params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #edit' do
    it_behaves_like 'editing snippet checks blob is binary' do
      let(:snippet) { create(:project_snippet, :private, project: project, author: user) }
      let(:params) do
        {
          namespace_id: project.namespace,
          project_id: project,
          id: snippet
        }
      end

      subject { get :edit, params: params }
    end
  end
end
