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

          expect(response).to have_http_status(200)
          expect(response).to render_template('show')
        end
      end
    end

    context 'when public visibility level is restricted' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      context 'when logged out' do
        it 'renders 404' do
          get :show, username: user.username
          expect(response).to have_http_status(404)
        end
      end

      context 'when logged in' do
        before { sign_in(user) }

        it 'renders show' do
          get :show, username: user.username
          expect(response).to have_http_status(200)
          expect(response).to render_template('show')
        end
      end
    end

    context 'when requesting the canonical path' do
      let(:user) { create(:user, username: 'CamelCaseUser') }

      before { sign_in(user) }

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
        end
      end
    end

    context 'when requesting a redirected path' do
      let(:redirect_route) { user.namespace.redirect_routes.create(path: 'old-username') }

      it 'redirects to the canonical path' do
        get :show, username: redirect_route.path

        expect(response).to redirect_to(user)
        expect(controller).to set_flash[:notice].to(/moved/)
      end
    end

    context 'when a user by that username does not exist' do
      context 'when logged out' do
        it 'renders 404 (does not redirect to login)' do
          get :show, username: 'nonexistent'
          expect(response).to have_http_status(404)
        end
      end

      context 'when logged in' do
        before { sign_in(user) }

        it 'renders 404' do
          get :show, username: 'nonexistent'
          expect(response).to have_http_status(404)
        end
      end
    end
  end

  describe 'GET #calendar' do
    it 'renders calendar' do
      sign_in(user)

      get :calendar, username: user.username

      expect(response).to render_template('calendar')
    end

    context 'forked project' do
      let(:project) { create(:empty_project) }
      let(:forked_project) { Projects::ForkService.new(project, user).execute }

      before do
        sign_in(user)
        project.team << [user, :developer]
        EventCreateService.new.push(project, user, [])
        EventCreateService.new.push(forked_project, user, [])
      end

      it 'includes forked projects' do
        get :calendar, username: user.username
        expect(assigns(:contributions_calendar).projects.count).to eq(2)
      end
    end

    context 'when requesting the canonical path' do
      let(:user) { create(:user, username: 'CamelCaseUser') }

      before { sign_in(user) }

      context 'with exactly matching casing' do
        it 'responds with success' do
          get :calendar, username: user.username

          expect(response).to be_success
        end
      end

      context 'with different casing' do
        it 'redirects to the correct casing' do
          get :calendar, username: user.username.downcase

          expect(response).to redirect_to(user_calendar_path(user))
        end
      end
    end

    context 'when requesting a redirected path' do
      let(:redirect_route) { user.namespace.redirect_routes.create(path: 'old-username') }

      it 'redirects to the canonical path' do
        get :calendar, username: redirect_route.path

        expect(response).to redirect_to(user_calendar_path(user))
        expect(controller).to set_flash[:notice].to(/moved/)
      end
    end
  end

  describe 'GET #calendar_activities' do
    let!(:project) { create(:empty_project) }
    let(:user) { create(:user) }

    before do
      allow_any_instance_of(User).to receive(:contributed_projects_ids).and_return([project.id])

      sign_in(user)
      project.team << [user, :developer]
    end

    it 'assigns @calendar_date' do
      get :calendar_activities, username: user.username, date: '2014-07-31'
      expect(assigns(:calendar_date)).to eq(Date.parse('2014-07-31'))
    end

    it 'renders calendar_activities' do
      get :calendar_activities, username: user.username
      expect(response).to render_template('calendar_activities')
    end

    context 'when requesting the canonical path' do
      let(:user) { create(:user, username: 'CamelCaseUser') }

      context 'with exactly matching casing' do
        it 'responds with success' do
          get :calendar_activities, username: user.username

          expect(response).to be_success
        end
      end

      context 'with different casing' do
        it 'redirects to the correct casing' do
          get :calendar_activities, username: user.username.downcase

          expect(response).to redirect_to(user_calendar_activities_path(user))
        end
      end
    end

    context 'when requesting a redirected path' do
      let(:redirect_route) { user.namespace.redirect_routes.create(path: 'old-username') }

      it 'redirects to the canonical path' do
        get :calendar_activities, username: redirect_route.path

        expect(response).to redirect_to(user_calendar_activities_path(user))
        expect(controller).to set_flash[:notice].to(/moved/)
      end
    end
  end

  describe 'GET #snippets' do
    before do
      sign_in(user)
    end

    context 'format html' do
      it 'renders snippets page' do
        get :snippets, username: user.username
        expect(response).to have_http_status(200)
        expect(response).to render_template('show')
      end
    end

    context 'format json' do
      it 'response with snippets json data' do
        get :snippets, username: user.username, format: :json
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to have_key('html')
      end
    end

    context 'when requesting the canonical path' do
      let(:user) { create(:user, username: 'CamelCaseUser') }

      context 'with exactly matching casing' do
        it 'responds with success' do
          get :snippets, username: user.username

          expect(response).to be_success
        end
      end

      context 'with different casing' do
        it 'redirects to the correct casing' do
          get :snippets, username: user.username.downcase

          expect(response).to redirect_to(user_snippets_path(user))
        end
      end
    end

    context 'when requesting a redirected path' do
      let(:redirect_route) { user.namespace.redirect_routes.create(path: 'old-username') }

      it 'redirects to the canonical path' do
        get :snippets, username: redirect_route.path

        expect(response).to redirect_to(user_snippets_path(user))
        expect(controller).to set_flash[:notice].to(/moved/)
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
end
