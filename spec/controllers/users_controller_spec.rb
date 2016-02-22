require 'spec_helper'

describe UsersController do
  let(:user) { create(:user) }

  describe 'GET #show' do
    it 'is case-insensitive' do
      user = create(:user, username: 'CamelCaseUser')
      sign_in(user)

      get :show, username: user.username.downcase

      expect(response).to be_success
    end

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

          expect(response).to be_success
          expect(response).to render_template('show')
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
      let!(:project) { create(:project) }
      let!(:forked_project) { Projects::ForkService.new(project, user).execute }

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
  end

  describe 'GET #calendar_activities' do
    let!(:project) { create(:project) }
    let!(:user) { create(:user) }

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
  end
end
