# frozen_string_literal: true

require 'spec_helper'

describe UsersController do
  let(:user) { create(:user) }
  let(:private_user) { create(:user, private_profile: true) }
  let(:public_user) { create(:user) }

  describe 'GET #show' do
    context 'with rendered views' do
      render_views

      describe 'when logged in' do
        before do
          sign_in(user)
        end

        it 'renders the show template' do
          get :show, params: { username: user.username }

          expect(response).to be_successful
          expect(response).to render_template('show')
        end
      end

      describe 'when logged out' do
        it 'renders the show template' do
          get :show, params: { username: user.username }

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
          get :show, params: { username: user.username }
          expect(response).to redirect_to new_user_session_path
        end
      end

      context 'when logged in' do
        before do
          sign_in(user)
        end

        it 'renders show' do
          get :show, params: { username: user.username }
          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template('show')
        end
      end
    end

    context 'when a user by that username does not exist' do
      context 'when logged out' do
        it 'redirects to login page' do
          get :show, params: { username: 'nonexistent' }
          expect(response).to redirect_to new_user_session_path
        end
      end

      context 'when logged in' do
        before do
          sign_in(user)
        end

        it 'renders 404' do
          get :show, params: { username: 'nonexistent' }
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
        get :show, params: { username: user }, format: :json

        expect(assigns(:events)).not_to be_empty
      end

      it 'hides events if the user cannot read cross project' do
        allow(Ability).to receive(:allowed?).and_call_original
        expect(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }

        get :show, params: { username: user }, format: :json

        expect(assigns(:events)).to be_empty
      end

      it 'hides events if the user has a private profile' do
        Gitlab::DataBuilder::Push.build_sample(project, private_user)

        get :show, params: { username: private_user.username }, format: :json

        expect(assigns(:events)).to be_empty
      end
    end
  end

  describe 'GET #calendar' do
    context 'for user' do
      let(:project) { create(:project) }

      before do
        sign_in(user)
        project.add_developer(user)
      end

      context 'with public profile' do
        it 'renders calendar' do
          push_data = Gitlab::DataBuilder::Push.build_sample(project, public_user)
          EventCreateService.new.push(project, public_user, push_data)

          get :calendar, params: { username: public_user.username }, format: :json

          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'with private profile' do
        it 'does not render calendar' do
          push_data = Gitlab::DataBuilder::Push.build_sample(project, private_user)
          EventCreateService.new.push(project, private_user, push_data)

          get :calendar, params: { username: private_user.username }, format: :json

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
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
        get :calendar, params: { username: user.username }
        expect(assigns(:contributions_calendar).projects.count).to eq(2)
      end
    end
  end

  describe 'GET #calendar_activities' do
    let!(:project) { create(:project) }
    let(:user) { create(:user) }

    before do
      allow_next_instance_of(User) do |instance|
        allow(instance).to receive(:contributed_projects_ids).and_return([project.id])
      end

      sign_in(user)
      project.add_developer(user)
    end

    it 'assigns @calendar_date' do
      get :calendar_activities, params: { username: user.username, date: '2014-07-31' }
      expect(assigns(:calendar_date)).to eq(Date.parse('2014-07-31'))
    end

    context 'for user' do
      context 'with public profile' do
        let(:issue) { create(:issue, project: project, author: user) }
        let(:note) { create(:note, noteable: issue, author: user, project: project) }

        render_views

        before do
          create_push_event
          create_note_event
        end

        it 'renders calendar_activities' do
          get :calendar_activities, params: { username: public_user.username }

          expect(assigns[:events]).not_to be_empty
        end

        it 'avoids N+1 queries', :request_store do
          get :calendar_activities, params: { username: public_user.username }

          control = ActiveRecord::QueryRecorder.new { get :calendar_activities, params: { username: public_user.username } }

          create_push_event
          create_note_event

          expect { get :calendar_activities, params: { username: public_user.username } }.not_to exceed_query_limit(control)
        end
      end

      context 'with private profile' do
        it 'does not render calendar_activities' do
          push_data = Gitlab::DataBuilder::Push.build_sample(project, private_user)
          EventCreateService.new.push(project, private_user, push_data)

          get :calendar_activities, params: { username: private_user.username }
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'external authorization' do
        subject { get :calendar_activities, params: { username: user.username } }

        it_behaves_like 'disabled when using an external authorization service'
      end

      def create_push_event
        push_data = Gitlab::DataBuilder::Push.build_sample(project, public_user)
        EventCreateService.new.push(project, public_user, push_data)
      end

      def create_note_event
        EventCreateService.new.leave_note(note, public_user)
      end
    end
  end

  describe 'GET #contributed' do
    let(:project) { create(:project, :public) }
    let(:current_user) { create(:user) }

    before do
      sign_in(current_user)

      project.add_developer(public_user)
      project.add_developer(private_user)
    end

    context 'with public profile' do
      it 'renders contributed projects' do
        create(:push_event, project: project, author: public_user)

        get :contributed, params: { username: public_user.username }

        expect(assigns[:contributed_projects]).not_to be_empty
      end
    end

    context 'with private profile' do
      it 'does not render contributed projects' do
        create(:push_event, project: project, author: private_user)

        get :contributed, params: { username: private_user.username }

        expect(assigns[:contributed_projects]).to be_empty
      end
    end
  end

  describe 'GET #snippets' do
    before do
      sign_in(user)
    end

    context 'format html' do
      it 'renders snippets page' do
        get :snippets, params: { username: user.username }
        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template('show')
      end
    end

    context 'format json' do
      it 'response with snippets json data' do
        get :snippets, params: { username: user.username }, format: :json
        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to have_key('html')
      end
    end

    context 'external authorization' do
      subject { get :snippets, params: { username: user.username } }

      it_behaves_like 'disabled when using an external authorization service'
    end
  end

  describe 'GET #exists' do
    before do
      sign_in(user)
    end

    context 'when user exists' do
      it 'returns JSON indicating the user exists' do
        get :exists, params: { username: user.username }

        expected_json = { exists: true }.to_json
        expect(response.body).to eq(expected_json)
      end

      context 'when the casing is different' do
        let(:user) { create(:user, username: 'CamelCaseUser') }

        it 'returns JSON indicating the user exists' do
          get :exists, params: { username: user.username.downcase }

          expected_json = { exists: true }.to_json
          expect(response.body).to eq(expected_json)
        end
      end
    end

    context 'when the user does not exist' do
      it 'returns JSON indicating the user does not exist' do
        get :exists, params: { username: 'foo' }

        expected_json = { exists: false }.to_json
        expect(response.body).to eq(expected_json)
      end

      context 'when a user changed their username' do
        let(:redirect_route) { user.namespace.redirect_routes.create(path: 'old-username') }

        it 'returns JSON indicating a user by that username does not exist' do
          get :exists, params: { username: 'old-username' }

          expected_json = { exists: false }.to_json
          expect(response.body).to eq(expected_json)
        end
      end
    end
  end

  describe 'GET #suggests' do
    context 'when user exists' do
      it 'returns JSON indicating the user exists and a suggestion' do
        get :suggests, params: { username: user.username }

        expected_json = { exists: true, suggests: ["#{user.username}1"] }.to_json
        expect(response.body).to eq(expected_json)
      end

      context 'when the casing is different' do
        let(:user) { create(:user, username: 'CamelCaseUser') }

        it 'returns JSON indicating the user exists and a suggestion' do
          get :suggests, params: { username: user.username.downcase }

          expected_json = { exists: true, suggests: ["#{user.username.downcase}1"] }.to_json
          expect(response.body).to eq(expected_json)
        end
      end
    end

    context 'when the user does not exist' do
      it 'returns JSON indicating the user does not exist' do
        get :suggests, params: { username: 'foo' }

        expected_json = { exists: false, suggests: [] }.to_json
        expect(response.body).to eq(expected_json)
      end

      context 'when a user changed their username' do
        let(:redirect_route) { user.namespace.redirect_routes.create(path: 'old-username') }

        it 'returns JSON indicating a user by that username does not exist' do
          get :suggests, params: { username: 'old-username' }

          expected_json = { exists: false, suggests: [] }.to_json
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
              get :show, params: { username: user.username }

              expect(response).to be_successful
            end
          end

          context 'with different casing' do
            it 'redirects to the correct casing' do
              get :show, params: { username: user.username.downcase }

              expect(response).to redirect_to(user)
              expect(controller).not_to set_flash[:notice]
            end
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { user.namespace.redirect_routes.create(path: 'old-path') }

          it 'redirects to the canonical path' do
            get :show, params: { username: redirect_route.path }

            expect(response).to redirect_to(user)
            expect(controller).to set_flash[:notice].to(user_moved_message(redirect_route, user))
          end

          context 'when the old path is a substring of the scheme or host' do
            let(:redirect_route) { user.namespace.redirect_routes.create(path: 'http') }

            it 'does not modify the requested host' do
              get :show, params: { username: redirect_route.path }

              expect(response).to redirect_to(user)
              expect(controller).to set_flash[:notice].to(user_moved_message(redirect_route, user))
            end
          end

          context 'when the old path is substring of users' do
            let(:redirect_route) { user.namespace.redirect_routes.create(path: 'ser') }

            it 'redirects to the canonical path' do
              get :show, params: { username: redirect_route.path }

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
              get :projects, params: { username: user.username }

              expect(response).to be_successful
            end
          end

          context 'with different casing' do
            it 'redirects to the correct casing' do
              get :projects, params: { username: user.username.downcase }

              expect(response).to redirect_to(user_projects_path(user))
              expect(controller).not_to set_flash[:notice]
            end
          end
        end

        context 'when requesting a redirected path' do
          let(:redirect_route) { user.namespace.redirect_routes.create(path: 'old-path') }

          it 'redirects to the canonical path' do
            get :projects, params: { username: redirect_route.path }

            expect(response).to redirect_to(user_projects_path(user))
            expect(controller).to set_flash[:notice].to(user_moved_message(redirect_route, user))
          end

          context 'when the old path is a substring of the scheme or host' do
            let(:redirect_route) { user.namespace.redirect_routes.create(path: 'http') }

            it 'does not modify the requested host' do
              get :projects, params: { username: redirect_route.path }

              expect(response).to redirect_to(user_projects_path(user))
              expect(controller).to set_flash[:notice].to(user_moved_message(redirect_route, user))
            end
          end

          context 'when the old path is substring of users' do
            let(:redirect_route) { user.namespace.redirect_routes.create(path: 'ser') }

            # I.e. /users/ser should not become /ufoos/ser
            it 'does not modify the /users part of the path' do
              get :projects, params: { username: redirect_route.path }

              expect(response).to redirect_to(user_projects_path(user))
              expect(controller).to set_flash[:notice].to(user_moved_message(redirect_route, user))
            end
          end
        end
      end
    end
  end

  context 'token authentication' do
    it_behaves_like 'authenticates sessionless user', :show, :atom, public: true do
      before do
        default_params.merge!(username: user.username)
      end
    end
  end

  def user_moved_message(redirect_route, user)
    "User '#{redirect_route.path}' was moved to '#{user.full_path}'. Please update any links and bookmarks that may still have the old path."
  end
end
