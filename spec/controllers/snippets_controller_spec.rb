require 'spec_helper'

describe SnippetsController do
  let(:user) { create(:user) }

  describe 'GET #new' do
    context 'when signed in' do
      before do
        sign_in(user)
      end

      it 'responds with status 200' do
        get :new

        expect(response).to have_http_status(200)
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

            expect(response).to have_http_status(404)
          end
        end

        context 'when signed in user is the author' do
          it 'renders the snippet' do
            get :show, id: personal_snippet.to_param

            expect(assigns(:snippet)).to eq(personal_snippet)
            expect(response).to have_http_status(200)
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
          expect(response).to have_http_status(200)
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
          expect(response).to have_http_status(200)
        end
      end

      context 'when not signed in' do
        it 'renders the snippet' do
          get :show, id: personal_snippet.to_param

          expect(assigns(:snippet)).to eq(personal_snippet)
          expect(response).to have_http_status(200)
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

          expect(response).to have_http_status(404)
        end
      end

      context 'when not signed in' do
        it 'responds with status 404' do
          get :show, id: 'doesntexist'

          expect(response).to have_http_status(404)
        end
      end
    end
  end

  describe 'POST #create' do
    def create_snippet(snippet_params = {})
      sign_in(user)

      post :create, {
        personal_snippet: { title: 'Title', content: 'Content' }.merge(snippet_params)
      }
    end

    context 'when the snippet is spam' do
      before do
        allow_any_instance_of(AkismetService).to receive(:is_spam?).and_return(true)
      end

      context 'when the snippet is private' do
        it 'creates the snippet' do
          expect { create_snippet(visibility_level: Snippet::PRIVATE) }.
            to change { Snippet.count }.by(1)
        end
      end

      context 'when the snippet is public' do
        it 'rejects the shippet' do
          expect { create_snippet(visibility_level: Snippet::PUBLIC) }.
            not_to change { Snippet.count }
          expect(response).to render_template(:new)
        end

        it 'creates a spam log' do
          expect { create_snippet(visibility_level: Snippet::PUBLIC) }.
            to change { SpamLog.count }.by(1)
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

  %w(raw download).each do |action|
    describe "GET #{action}" do
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
              get action, id: other_personal_snippet.to_param

              expect(response).to have_http_status(404)
            end
          end

          context 'when signed in user is the author' do
            before { get action, id: personal_snippet.to_param }

            it 'responds with status 200' do
              expect(assigns(:snippet)).to eq(personal_snippet)
              expect(response).to have_http_status(200)
            end

            it 'has expected headers' do
              expect(response.header['Content-Type']).to eq('text/plain; charset=utf-8')

              if action == :download
                expect(response.header['Content-Disposition']).to match(/attachment/)
              elsif action == :raw
                expect(response.header['Content-Disposition']).to match(/inline/)
              end
            end
          end
        end

        context 'when not signed in' do
          it 'redirects to the sign in page' do
            get action, id: personal_snippet.to_param

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
            get action, id: personal_snippet.to_param

            expect(assigns(:snippet)).to eq(personal_snippet)
            expect(response).to have_http_status(200)
          end
        end

        context 'when not signed in' do
          it 'redirects to the sign in page' do
            get action, id: personal_snippet.to_param

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
            get action, id: personal_snippet.to_param

            expect(assigns(:snippet)).to eq(personal_snippet)
            expect(response).to have_http_status(200)
          end
        end

        context 'when not signed in' do
          it 'responds with status 200' do
            get action, id: personal_snippet.to_param

            expect(assigns(:snippet)).to eq(personal_snippet)
            expect(response).to have_http_status(200)
          end
        end
      end

      context 'when the personal snippet does not exist' do
        context 'when signed in' do
          before do
            sign_in(user)
          end

          it 'responds with status 404' do
            get action, id: 'doesntexist'

            expect(response).to have_http_status(404)
          end
        end

        context 'when not signed in' do
          it 'responds with status 404' do
            get action, id: 'doesntexist'

            expect(response).to have_http_status(404)
          end
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
end
