require 'spec_helper'

describe SnippetsController do
  describe 'GET #show' do
    let(:user) { create(:user) }

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

            expect(response.status).to eq(404)
          end
        end

        context 'when signed in user is the author' do
          it 'renders the snippet' do
            get :show, id: personal_snippet.to_param

            expect(assigns(:snippet)).to eq(personal_snippet)
            expect(response.status).to eq(200)
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
          expect(response.status).to eq(200)
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
          expect(response.status).to eq(200)
        end
      end

      context 'when not signed in' do
        it 'renders the snippet' do
          get :show, id: personal_snippet.to_param

          expect(assigns(:snippet)).to eq(personal_snippet)
          expect(response.status).to eq(200)
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

          expect(response.status).to eq(404)
        end
      end

      context 'when not signed in' do
        it 'responds with status 404' do
          get :show, id: 'doesntexist'

          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe 'GET #raw' do
    let(:user) { create(:user) }

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

            expect(response.status).to eq(404)
          end
        end

        context 'when signed in user is the author' do
          it 'renders the raw snippet' do
            get :raw, id: personal_snippet.to_param

            expect(assigns(:snippet)).to eq(personal_snippet)
            expect(response.status).to eq(200)
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

        it 'renders the raw snippet' do
          get :raw, id: personal_snippet.to_param

          expect(assigns(:snippet)).to eq(personal_snippet)
          expect(response.status).to eq(200)
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

        it 'renders the raw snippet' do
          get :raw, id: personal_snippet.to_param

          expect(assigns(:snippet)).to eq(personal_snippet)
          expect(response.status).to eq(200)
        end
      end

      context 'when not signed in' do
        it 'renders the raw snippet' do
          get :raw, id: personal_snippet.to_param

          expect(assigns(:snippet)).to eq(personal_snippet)
          expect(response.status).to eq(200)
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

          expect(response.status).to eq(404)
        end
      end

      context 'when not signed in' do
        it 'responds with status 404' do
          get :raw, id: 'doesntexist'

          expect(response.status).to eq(404)
        end
      end
    end
  end
end
