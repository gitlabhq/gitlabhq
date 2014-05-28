require 'spec_helper'

describe UsersController do
  let(:user)    { create(:user, username: 'test',
                                name: 'Test', email: 'test@aelogica.com',
                                password: 'test1234')
  }

  let(:project) { create(:project) }
  let(:users_project) { create(:users_project, user: user, project: project) }

  before do
    users_project
    sign_in(user)
  end

  describe 'GET #show' do
    it 'renders the show template' do
      get :show, username: user.username
      expect(response.status).to eq(200)
    end

    context 'when there is no repository' do
      it 'should call helper methods' do
        timestamp = {}
        UsersHelper.stub(:create_timestamp).with(users_project).
        and_return(timestamp)
        date = double(:date, year: 2014, month: 'May')
        DateTime.stub_chain(:now, :to_date).and_return(date)
        UsersHelper.stub(:create_timecopy).and_return(date)
        get :show, username: user.username
        expect(assigns(:timestamps)).to eq(timestamp.to_json)
        expect(assigns(:time_copy)).to eq(date)
      end
    end
  end
end
