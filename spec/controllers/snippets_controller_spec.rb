# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:public_snippet) { create(:personal_snippet, :public, :repository, author: user) }

  describe 'GET #index' do
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

  describe 'GET #new' do
    context 'when signed in' do
      before do
        sign_in(user)
      end

      it 'responds with status 200' do
        get :new

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when user is not allowed to create a personal snippet' do
        let(:user) { create(:user, :external) }

        it 'responds with status 404' do
          get :new

          expect(response).to have_gitlab_http_status(:not_found)
        end
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
    shared_examples 'successful response' do
      it 'renders the snippet' do
        subject

        expect(assigns(:snippet)).to eq(personal_snippet)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the personal snippet is private' do
      let_it_be(:personal_snippet) { create(:personal_snippet, :private, :repository, author: user) }

      context 'when signed in' do
        before do
          sign_in(user)
        end

        context 'when signed in user is not the author' do
          let(:other_personal_snippet) { create(:personal_snippet, :private, author: other_user) }

          it 'responds with status 404' do
            get :show, params: { id: other_personal_snippet.to_param }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when signed in user is the author' do
          it_behaves_like 'successful response' do
            subject { get :show, params: { id: personal_snippet.to_param } }
          end

          it 'responds with status 404 when embeddable content is requested' do
            get :show, params: { id: personal_snippet.to_param }, format: :js

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when not signed in' do
        it 'redirects to the sign in page' do
          get :show, params: { id: personal_snippet.to_param }

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'when the personal snippet is internal' do
      let_it_be(:personal_snippet) { create(:personal_snippet, :internal, :repository, author: user) }

      context 'when signed in' do
        before do
          sign_in(user)
        end

        it_behaves_like 'successful response' do
          subject { get :show, params: { id: personal_snippet.to_param } }
        end

        it 'responds with status 404 when embeddable content is requested' do
          get :show, params: { id: personal_snippet.to_param }, format: :js

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when not signed in' do
        it 'redirects to the sign in page' do
          get :show, params: { id: personal_snippet.to_param }

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'when the personal snippet is public' do
      let(:personal_snippet) { public_snippet }

      context 'when signed in' do
        before do
          sign_in(user)
        end

        it_behaves_like 'successful response' do
          subject { get :show, params: { id: public_snippet.to_param } }
        end

        it 'responds with status 200 when embeddable content is requested' do
          get :show, params: { id: public_snippet.to_param }, format: :js

          expect(assigns(:snippet)).to eq(public_snippet)
          expect(response).to have_gitlab_http_status(:ok)
        end

        it_behaves_like 'tracking unique hll events' do
          subject(:request) { get :show, params: { id: public_snippet.to_param } }

          let(:target_event) { 'i_snippets_show' }
          let(:expected_value) { instance_of(String) }
        end
      end

      context 'when not signed in' do
        it 'renders the snippet' do
          get :show, params: { id: public_snippet.to_param }

          expect(assigns(:snippet)).to eq(public_snippet)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when the personal snippet does not exist' do
      context 'when signed in' do
        before do
          sign_in(user)
        end

        it 'responds with status 404' do
          get :show, params: { id: non_existing_record_id }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when not signed in' do
        it 'responds with status 404' do
          get :show, params: { id: non_existing_record_id }

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end

  describe 'POST #mark_as_spam' do
    before do
      allow_next_instance_of(Spam::AkismetService) do |instance|
        allow(instance).to receive_messages(submit_spam: true)
      end

      stub_application_setting(akismet_enabled: true)
    end

    def mark_as_spam
      admin = create(:admin)
      create(:user_agent_detail, subject: public_snippet)
      sign_in(admin)

      post :mark_as_spam, params: { id: public_snippet.id }
    end

    it 'updates the snippet', :enable_admin_mode do
      mark_as_spam

      expect(public_snippet.reload).not_to be_submittable_as_spam
    end
  end

  describe "GET #raw" do
    let(:inline) { nil }
    let(:params) { { id: snippet.to_param, inline: inline } }

    subject { get :raw, params: params }

    shared_examples '200 status' do
      before do
        subject
      end

      it 'responds with status 200' do
        expect(assigns(:snippet)).to eq(snippet)
        expect(response).to have_gitlab_http_status(:ok)
      end

      it "sets #{Gitlab::Workhorse::DETECT_HEADER} header" do
        expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq 'true'
      end
    end

    shared_examples 'CRLF line ending' do
      let(:content) { "first line\r\nsecond line\r\nthird line" }
      let(:formatted_content) { content.gsub(/\r\n/, "\n") }
      let(:snippet) { public_snippet }

      before do
        allow_next_instance_of(Blob) do |instance|
          allow(instance).to receive(:data).and_return(content)
        end

        subject
      end

      it 'returns LF line endings by default' do
        expect(response.body).to eq(formatted_content)
      end

      context 'when parameter present' do
        let(:params) { { id: snippet.to_param, line_ending: :raw } }

        it 'does not convert line endings when parameter present' do
          expect(response.body).to eq(content)
        end
      end
    end

    shared_examples 'successful response' do
      it_behaves_like '200 status'

      it 'has expected blob headers' do
        subject

        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
        expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq 'true'
      end

      it_behaves_like 'content disposition headers'

      it 'sets cache_control public header based on snippet visibility' do
        subject

        expect(response.cache_control[:public]).to eq snippet.public?
      end

      context 'when snippet repository is empty' do
        before do
          allow_any_instance_of(Repository).to receive(:empty?).and_return(true)
        end

        it_behaves_like '200 status'
        it_behaves_like 'CRLF line ending'

        it 'returns snippet database content' do
          subject

          expect(response.body).to eq snippet.content
          expect(response.header['Content-Type']).to eq('text/plain; charset=utf-8')
        end

        it_behaves_like 'content disposition headers'
      end
    end

    context 'when the personal snippet is private' do
      let_it_be(:snippet) { create(:personal_snippet, :private, :repository, author: user) }

      context 'when signed in' do
        before do
          sign_in(user)
        end

        context 'when signed in user is not the author' do
          let(:other_personal_snippet) { create(:personal_snippet, :private, author: other_user) }

          it 'responds with status 404' do
            get :raw, params: { id: other_personal_snippet.to_param }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when signed in user is the author' do
          it_behaves_like 'successful response'
        end
      end

      context 'when not signed in' do
        it 'redirects to the sign in page' do
          subject

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'when the personal snippet is internal' do
      let_it_be(:snippet) { create(:personal_snippet, :internal, :repository, author: user) }

      context 'when signed in' do
        before do
          sign_in(user)
        end

        it_behaves_like 'successful response'
      end

      context 'when not signed in' do
        it 'redirects to the sign in page' do
          subject

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'when the personal snippet is public' do
      let(:snippet) { public_snippet }

      context 'when signed in' do
        before do
          sign_in(user)
        end

        it_behaves_like 'successful response'
      end

      context 'when not signed in' do
        it 'responds with status 200' do
          subject

          expect(assigns(:snippet)).to eq(snippet)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when the personal snippet does not exist' do
      context 'when signed in' do
        before do
          sign_in(user)
        end

        it 'responds with status 404' do
          get :raw, params: { id: non_existing_record_id }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when not signed in' do
        it 'redirects to the sign in path' do
          get :raw, params: { id: non_existing_record_id }

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end

  context 'award emoji on snippets' do
    let(:personal_snippet) { public_snippet }

    before do
      sign_in(other_user)
    end

    describe 'POST #toggle_award_emoji' do
      it "toggles the award emoji" do
        expect do
          post(:toggle_award_emoji, params: { id: personal_snippet.to_param, name: AwardEmoji::THUMBS_UP })
        end.to change { personal_snippet.award_emoji.count }.from(0).to(1)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it "removes the already awarded emoji" do
        post(:toggle_award_emoji, params: { id: personal_snippet.to_param, name: AwardEmoji::THUMBS_UP })

        expect do
          post(:toggle_award_emoji, params: { id: personal_snippet.to_param, name: AwardEmoji::THUMBS_UP })
        end.to change { personal_snippet.award_emoji.count }.from(1).to(0)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'POST #preview_markdown' do
    it 'renders json in a correct format' do
      sign_in(user)

      post :preview_markdown, params: { id: public_snippet, text: '*Markdown* text' }

      expect(json_response.keys).to match_array(%w[body references])
    end
  end
end
