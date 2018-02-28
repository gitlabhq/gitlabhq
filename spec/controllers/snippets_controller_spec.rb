require 'spec_helper'

describe SnippetsController do
  let(:user) { create(:user) }

  describe 'GET #index' do
    let(:user) { create(:user) }

    context 'when username parameter is present' do
      it 'renders snippets of a user when username is present' do
        get :index, username: user.username

        expect(response).to render_template(:index)
      end
    end

    context 'when username parameter is not present' do
      it 'redirects to explore snippets page when user is not logged in' do
        get :index

        expect(response).to redirect_to(explore_snippets_path)
      end

      it 'redirects to snippets dashboard page when user is logged in' do
        sign_in(user)

        get :index

        expect(response).to redirect_to(dashboard_snippets_path)
      end
    end
  end

  describe 'GET #new' do
    context 'when signed in' do
      before do
        sign_in(user)
      end

      it 'responds with status 200' do
        get :new

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'when not signed in' do
      it 'redirects to the sign in page' do
        get :new

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #show' do
    context 'when the personal snippet is private' do
      let(:personal_snippet) { create(:personal_snippet, :private, author: user) }

      context 'when signed in' do
        before do
          sign_in(user)
        end

        context 'when signed in user is not the author' do
          let(:other_author) { create(:author) }
          let(:other_personal_snippet) { create(:personal_snippet, :private, author: other_author) }

          it 'responds with status 404' do
            get :show, id: other_personal_snippet.to_param

            expect(response).to have_gitlab_http_status(404)
          end
        end

        context 'when signed in user is the author' do
          it 'renders the snippet' do
            get :show, id: personal_snippet.to_param

            expect(assigns(:snippet)).to eq(personal_snippet)
            expect(response).to have_gitlab_http_status(200)
          end
        end
      end

      context 'when not signed in' do
        it 'redirects to the sign in page' do
          get :show, id: personal_snippet.to_param

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'when the personal snippet is internal' do
      let(:personal_snippet) { create(:personal_snippet, :internal, author: user) }

      context 'when signed in' do
        before do
          sign_in(user)
        end

        it 'renders the snippet' do
          get :show, id: personal_snippet.to_param

          expect(assigns(:snippet)).to eq(personal_snippet)
          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'when not signed in' do
        it 'redirects to the sign in page' do
          get :show, id: personal_snippet.to_param

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'when the personal snippet is public' do
      let(:personal_snippet) { create(:personal_snippet, :public, author: user) }

      context 'when signed in' do
        before do
          sign_in(user)
        end

        it 'renders the snippet' do
          get :show, id: personal_snippet.to_param

          expect(assigns(:snippet)).to eq(personal_snippet)
          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'when not signed in' do
        it 'renders the snippet' do
          get :show, id: personal_snippet.to_param

          expect(assigns(:snippet)).to eq(personal_snippet)
          expect(response).to have_gitlab_http_status(200)
        end
      end
    end

    context 'when the personal snippet does not exist' do
      context 'when signed in' do
        before do
          sign_in(user)
        end

        it 'responds with status 404' do
          get :show, id: 'doesntexist'

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when not signed in' do
        it 'responds with status 404' do
          get :show, id: 'doesntexist'

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end

  describe 'POST #create' do
    def create_snippet(snippet_params = {}, additional_params = {})
      sign_in(user)

      post :create, {
        personal_snippet: { title: 'Title', content: 'Content', description: 'Description' }.merge(snippet_params)
      }.merge(additional_params)

      Snippet.last
    end

    it 'creates the snippet correctly' do
      snippet = create_snippet(visibility_level: Snippet::PRIVATE)

      expect(snippet.title).to eq('Title')
      expect(snippet.content).to eq('Content')
      expect(snippet.description).to eq('Description')
    end

    context 'when the snippet description contains a file' do
      let(:picture_file) { '/-/system/temp/secret56/picture.jpg' }
      let(:text_file) { '/-/system/temp/secret78/text.txt' }
      let(:description) do
        "Description with picture: ![picture](/uploads#{picture_file}) and "\
        "text: [text.txt](/uploads#{text_file})"
      end

      before do
        allow(FileUtils).to receive(:mkdir_p)
        allow(FileUtils).to receive(:move)
      end

      subject { create_snippet({ description: description }, { files: [picture_file, text_file] }) }

      it 'creates the snippet' do
        expect { subject }.to change { Snippet.count }.by(1)
      end

      it 'stores the snippet description correctly' do
        snippet = subject

        expected_description = "Description with picture: "\
          "![picture](/uploads/-/system/personal_snippet/#{snippet.id}/secret56/picture.jpg) and "\
          "text: [text.txt](/uploads/-/system/personal_snippet/#{snippet.id}/secret78/text.txt)"

        expect(snippet.description).to eq(expected_description)
      end
    end

    context 'when the snippet is spam' do
      before do
        allow_any_instance_of(AkismetService).to receive(:spam?).and_return(true)
      end

      context 'when the snippet is private' do
        it 'creates the snippet' do
          expect { create_snippet(visibility_level: Snippet::PRIVATE) }
            .to change { Snippet.count }.by(1)
        end
      end

      context 'when the snippet is public' do
        it 'rejects the shippet' do
          expect { create_snippet(visibility_level: Snippet::PUBLIC) }
            .not_to change { Snippet.count }
        end

        it 'creates a spam log' do
          expect { create_snippet(visibility_level: Snippet::PUBLIC) }
            .to change { SpamLog.count }.by(1)
        end

        it 'renders :new with recaptcha disabled' do
          stub_application_setting(recaptcha_enabled: false)

          create_snippet(visibility_level: Snippet::PUBLIC)

          expect(response).to render_template(:new)
        end

        context 'recaptcha enabled' do
          before do
            stub_application_setting(recaptcha_enabled: true)
          end

          it 'renders :verify with recaptcha enabled' do
            create_snippet(visibility_level: Snippet::PUBLIC)

            expect(response).to render_template(:verify)
          end

          it 'renders snippet page when recaptcha verified' do
            spammy_title = 'Whatever'

            spam_logs = create_list(:spam_log, 2, user: user, title: spammy_title)
            snippet = create_snippet({ title: spammy_title },
                                     { spam_log_id: spam_logs.last.id,
                                       recaptcha_verification: true })

            expect(response).to redirect_to(snippet_path(snippet))
          end
        end
      end
    end
  end

  describe 'PUT #update' do
    let(:project) { create :project }
    let(:snippet) { create :personal_snippet, author: user, project: project, visibility_level: visibility_level }

    def update_snippet(snippet_params = {}, additional_params = {})
      sign_in(user)

      put :update, {
        id: snippet.id,
        personal_snippet: { title: 'Title', content: 'Content' }.merge(snippet_params)
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

      context 'when a private snippet is made public' do
        let(:visibility_level) { Snippet::PRIVATE }

        it 'rejects the snippet' do
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

            expect(response).to redirect_to(snippet_path(snippet))
          end
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

            expect(response).to redirect_to(snippet_path(snippet))
          end
        end
      end
    end
  end

  describe 'POST #mark_as_spam' do
    let(:snippet) { create(:personal_snippet, :public, author: user) }

    before do
      allow_any_instance_of(AkismetService).to receive_messages(submit_spam: true)
      stub_application_setting(akismet_enabled: true)
    end

    def mark_as_spam
      admin = create(:admin)
      create(:user_agent_detail, subject: snippet)
      sign_in(admin)

      post :mark_as_spam, id: snippet.id
    end

    it 'updates the snippet' do
      mark_as_spam

      expect(snippet.reload).not_to be_submittable_as_spam
    end
  end

  describe "GET #raw" do
    context 'when the personal snippet is private' do
      let(:personal_snippet) { create(:personal_snippet, :private, author: user) }

      context 'when signed in' do
        before do
          sign_in(user)
        end

        context 'when signed in user is not the author' do
          let(:other_author) { create(:author) }
          let(:other_personal_snippet) { create(:personal_snippet, :private, author: other_author) }

          it 'responds with status 404' do
            get :raw, id: other_personal_snippet.to_param

            expect(response).to have_gitlab_http_status(404)
          end
        end

        context 'when signed in user is the author' do
          before do
            get :raw, id: personal_snippet.to_param
          end

          it 'responds with status 200' do
            expect(assigns(:snippet)).to eq(personal_snippet)
            expect(response).to have_gitlab_http_status(200)
          end

          it 'has expected headers' do
            expect(response.header['Content-Type']).to eq('text/plain; charset=utf-8')

            expect(response.header['Content-Disposition']).to match(/inline/)
          end
        end
      end

      context 'when not signed in' do
        it 'redirects to the sign in page' do
          get :raw, id: personal_snippet.to_param

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'when the personal snippet is internal' do
      let(:personal_snippet) { create(:personal_snippet, :internal, author: user) }

      context 'when signed in' do
        before do
          sign_in(user)
        end

        it 'responds with status 200' do
          get :raw, id: personal_snippet.to_param

          expect(assigns(:snippet)).to eq(personal_snippet)
          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'when not signed in' do
        it 'redirects to the sign in page' do
          get :raw, id: personal_snippet.to_param

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'when the personal snippet is public' do
      let(:personal_snippet) { create(:personal_snippet, :public, author: user) }

      context 'when signed in' do
        before do
          sign_in(user)
        end

        it 'responds with status 200' do
          get :raw, id: personal_snippet.to_param

          expect(assigns(:snippet)).to eq(personal_snippet)
          expect(response).to have_gitlab_http_status(200)
        end

        context 'CRLF line ending' do
          let(:personal_snippet) do
            create(:personal_snippet, :public, author: user, content: "first line\r\nsecond line\r\nthird line")
          end

          it 'returns LF line endings by default' do
            get :raw, id: personal_snippet.to_param

            expect(response.body).to eq("first line\nsecond line\nthird line")
          end

          it 'does not convert line endings when parameter present' do
            get :raw, id: personal_snippet.to_param, line_ending: :raw

            expect(response.body).to eq("first line\r\nsecond line\r\nthird line")
          end
        end
      end

      context 'when not signed in' do
        it 'responds with status 200' do
          get :raw, id: personal_snippet.to_param

          expect(assigns(:snippet)).to eq(personal_snippet)
          expect(response).to have_gitlab_http_status(200)
        end
      end
    end

    context 'when the personal snippet does not exist' do
      context 'when signed in' do
        before do
          sign_in(user)
        end

        it 'responds with status 404' do
          get :raw, id: 'doesntexist'

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when not signed in' do
        it 'redirects to the sign in path' do
          get :raw, id: 'doesntexist'

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end

  context 'award emoji on snippets' do
    let(:personal_snippet) { create(:personal_snippet, :public, author: user) }
    let(:another_user) { create(:user) }

    before do
      sign_in(another_user)
    end

    describe 'POST #toggle_award_emoji' do
      it "toggles the award emoji" do
        expect do
          post(:toggle_award_emoji, id: personal_snippet.to_param, name: "thumbsup")
        end.to change { personal_snippet.award_emoji.count }.from(0).to(1)

        expect(response.status).to eq(200)
      end

      it "removes the already awarded emoji" do
        post(:toggle_award_emoji, id: personal_snippet.to_param, name: "thumbsup")

        expect do
          post(:toggle_award_emoji, id: personal_snippet.to_param, name: "thumbsup")
        end.to change { personal_snippet.award_emoji.count }.from(1).to(0)

        expect(response.status).to eq(200)
      end
    end
  end

  describe 'POST #preview_markdown' do
    let(:snippet) { create(:personal_snippet, :public) }

    it 'renders json in a correct format' do
      sign_in(user)

      post :preview_markdown, id: snippet, text: '*Markdown* text'

      expect(JSON.parse(response.body).keys).to match_array(%w(body references))
    end
  end
end
