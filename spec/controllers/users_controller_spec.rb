require 'spec_helper'

describe UsersController do
  let(:user) { create(:user) }

  describe 'GET #show' do
    context 'with rendered views' do
      render_views

      describe 'when logged in' do
        before do
          sign_in(user)
        end

        it 'renders the show template' do
          get :show, username: user.username

          expect(response).to be_success
          expect(response).to render_template('show')
        end
      end

      describe 'when logged out' do
        it 'renders the show template' do
          get :show, username: user.username

          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template('show')
        end
      end
    end

    context 'when public visibility level is restricted' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      context 'when logged out' do
        it 'redirects to login page' do
          get :show, username: user.username
          expect(response).to redirect_to new_user_session_path
        end
      end

      context 'when logged in' do
        before do
          sign_in(user)
        end

        it 'renders show' do
          get :show, username: user.username
          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template('show')
        end
      end
    end

    context 'when a user by that username does not exist' do
      context 'when logged out' do
        it 'redirects to login page' do
          get :show, username: 'nonexistent'
          expect(response).to redirect_to new_user_session_path
        end
      end

      context 'when logged in' do
        before do
          sign_in(user)
        end

        it 'renders 404' do
          get :show, username: 'nonexistent'
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'json with events' do
      let(:project) { create(:project) }
      before do
        project.add_developer(user)
        Gitlab::DataBuilder::Push.build_sample(project, user)

        sign_in(user)
      end

      it 'loads events' do
        get :show, username: user, format: :json

        expect(assigns(:events)).not_to be_empty
      end

      it 'hides events if the user cannot read cross project' do
        allow(Ability).to receive(:allowed?).and_call_original
        expect(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }

        get :show, username: user, format: :json

        expect(assigns(:events)).to be_empty
      end
    end
  end

  describe 'GET #calendar' do
    it 'renders calendar' do
      sign_in(user)

      get :calendar, username: user.username, format: :json

      expect(response).to have_gitlab_http_status(200)
    end

    context 'forked project' do
      let(:project) { create(:project) }
      let(:forked_project) { Projects::ForkService.new(project, user).execute }

      before do
        sign_in(user)
        project.add_developer(user)

        push_data = Gitlab::DataBuilder::Push.build_sample(project, user)

        fork_push_data = Gitlab::DataBuilder::Push
          .build_sample(forked_project, user)

        EventCreateService.new.push(project, user, push_data)
        EventCreateService.new.push(forked_project, user, fork_push_data)
      end

      it 'includes forked projects' do
        get :calendar, username: user.username
        expect(assigns(:contributions_calendar).projects.count).to eq(2)
      end
    end
  end

  describe 'GET #calendar_activities' do
    let!(:project) { create(:project) }
    let(:user) { create(:user) }

    before do
      allow_any_instance_of(User).to receive(:contributed_projects_ids).and_return([project.id])

      sign_in(user)
      project.add_developer(user)
    end

    it 'assigns @calendar_date' do
      get :calendar_activities, username: user.username, date: '2014-07-31'
      expect(assigns(:calendar_date)).to eq(Date.parse('2014-07-31'))
    end

    it 'renders calendar_activities' do
      get :calendar_activities, username: user.username
      expect(response).to render_template('calendar_activities')
    end
  end

  describe 'GET #snippets' do
    before do
      sign_in(user)
    end

    context 'format html' do
      it 'renders snippets page' do
        get :snippets, username: user.username
        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template('show')
      end
    end

    context 'format json' do
      it 'response with snippets json data' do
        get :snippets, username: user.username, format: :json
        expect(response).to have_gitlab_http_status(200)
        expect(JSON.parse(response.body)).to have_key('html')
      end
    end
  end

  describe 'GET #exists' do
    before do
      sign_in(user)
    end

    context 'when user exists' do
      it 'returns JSON indicating the user exists' do
        get :exists, username: user.username

        expected_json = { exists: true }.to_json
        expect(response.body).to eq(expected_json)
      end

      context 'when the casing is different' do
        let(:user) { create(:user, username: 'CamelCaseUser') }

        it 'returns JSON indicating the user exists' do
          get :exists, username: user.username.downcase

          expected_json = { exists: true }.to_json
          expect(response.body).to eq(expected_json)
        end
      end
    end

    context 'when the user does not exist' do
      it 'returns JSON indicating the user does not exist' do
        get :exists, username: 'foo'

        expected_json = { exists: false }.to_json
        expect(response.body).to eq(expected_json)
      end

      context 'when a user changed their username' do
        let(:redirect_route) { user.namespace.redirect_routes.create(path: 'old-username') }

        it 'returns JSON indicating a user by that username does not exist' do
          get :exists, username: 'old-username'

          expected_json = { exists: false }.to_json
          expect(response.body).to eq(expected_json)
        end
      end
    end
  end

  describe '#ensure_canonical_path' do
    before do
      sign_in(user)
    end

    context 'for a GET request' do
      context 'when requesting users at the root path' do
        context 'when requesting the canonical path' do
          let(:user) { create(:user, username: 'CamelCaseUser') }

          context 'with exactly matching casing' do
            it 'responds with success' do
              get :show, username: user.username

              expect(response).to be_success
            end
          end

          context 'with different casing' do
            it 'redirects to the correct casing' do
              get :show, username: user.username.downcase

              expect(response).to redirect_to(user)
              expect(controller).not_to set_flash[:notice]
            end
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { user.namespace.redirect_routes.create(path: 'old-path') }

          it 'redirects to the canonical path' do
            get :show, username: redirect_route.path

            expect(response).to redirect_to(user)
            expect(controller).to set_flash[:notice].to(user_moved_message(redirect_route, user))
          end

          context 'when the old path is a substring of the scheme or host' do
            let(:redirect_route) { user.namespace.redirect_routes.create(path: 'http') }

            it 'does not modify the requested host' do
              get :show, username: redirect_route.path

              expect(response).to redirect_to(user)
              expect(controller).to set_flash[:notice].to(user_moved_message(redirect_route, user))
            end
          end

          context 'when the old path is substring of users' do
            let(:redirect_route) { user.namespace.redirect_routes.create(path: 'ser') }

            it 'redirects to the canonical path' do
              get :show, username: redirect_route.path

              expect(response).to redirect_to(user)
              expect(controller).to set_flash[:notice].to(user_moved_message(redirect_route, user))
            end
          end
        end
      end

      context 'when requesting users under the /users path' do
        context 'when requesting the canonical path' do
          let(:user) { create(:user, username: 'CamelCaseUser') }

          context 'with exactly matching casing' do
            it 'responds with success' do
              get :projects, username: user.username

              expect(response).to be_success
            end
          end

          context 'with different casing' do
            it 'redirects to the correct casing' do
              get :projects, username: user.username.downcase

              expect(response).to redirect_to(user_projects_path(user))
              expect(controller).not_to set_flash[:notice]
            end
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { user.namespace.redirect_routes.create(path: 'old-path') }

          it 'redirects to the canonical path' do
            get :projects, username: redirect_route.path

            expect(response).to redirect_to(user_projects_path(user))
            expect(controller).to set_flash[:notice].to(user_moved_message(redirect_route, user))
          end

          context 'when the old path is a substring of the scheme or host' do
            let(:redirect_route) { user.namespace.redirect_routes.create(path: 'http') }

            it 'does not modify the requested host' do
              get :projects, username: redirect_route.path

              expect(response).to redirect_to(user_projects_path(user))
              expect(controller).to set_flash[:notice].to(user_moved_message(redirect_route, user))
            end
          end

          context 'when the old path is substring of users' do
            let(:redirect_route) { user.namespace.redirect_routes.create(path: 'ser') }

            # I.e. /users/ser should not become /ufoos/ser
            it 'does not modify the /users part of the path' do
              get :projects, username: redirect_route.path

              expect(response).to redirect_to(user_projects_path(user))
              expect(controller).to set_flash[:notice].to(user_moved_message(redirect_route, user))
            end
          end
        end
      end
    end
  end

  def user_moved_message(redirect_route, user)
    "User '#{redirect_route.path}' was moved to '#{user.full_path}'. Please update any links and bookmarks that may still have the old path."
  end
end
