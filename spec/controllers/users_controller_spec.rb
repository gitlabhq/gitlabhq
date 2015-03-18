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
    include RepoHelpers
    let(:project) { create(:project) }
    let(:calendar_user) { create(:user, email: sample_commit.author_email) }
    let(:commit1) { '0ed8c6c6752e8c6ea63e7b92a517bf5ac1209c80' }
    let(:commit2) { '7d3b0f7cff5f37573aea97cebfd5692ea1689924' }

    before do
      allow_any_instance_of(User).to receive(:contributed_projects_ids).and_return([project.id])
      project.team << [user, :developer]
    end

    it 'assigns @commit_count' do
      get :calendar_activities, username: calendar_user.username, date: '2014-07-31'
      expect(assigns(:commit_count)).to eq(2)
    end

    it 'assigns @calendar_date' do
      get :calendar_activities, username: calendar_user.username, date: '2014-07-31'
      expect(assigns(:calendar_date)).to eq(Date.parse('2014-07-31'))
    end

    it 'assigns @calendar_activities' do
      get :calendar_activities, username: calendar_user.username, date: '2014-07-31'
      expect(assigns(:calendar_activities).values.flatten.map(&:id)).to eq([commit1, commit2])
    end

    it 'renders calendar_activities' do
      get :calendar_activities, username: calendar_user.username
      expect(response).to render_template('calendar_activities')
    end
  end
end
