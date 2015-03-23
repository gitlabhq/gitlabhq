require 'spec_helper'

describe UsersController do
  let(:user)    { create(:user, username: 'user1', name: 'User 1', email: 'user1@gitlab.com') }

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    render_views

    it 'renders the show template' do
      get :show, username: user.username
      expect(response.status).to eq(200)
      expect(response).to render_template('show')
    end
  end

  describe 'GET #calendar' do
    it 'renders calendar' do
      get :calendar, username: user.username
      expect(response).to render_template('calendar')
    end
  end

  describe 'GET #calendar_activities' do
    let!(:project) { create(:project) }
    let!(:user) { create(:user) }

    before do
      allow_any_instance_of(User).to receive(:contributed_projects_ids).and_return([project.id])
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
