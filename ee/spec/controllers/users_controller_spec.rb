require 'spec_helper'

describe UsersController do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #snippets' do
    subject { get :snippets, username: user.username }

    it_behaves_like 'disabled when using an external authorization service'
  end

  describe 'GET #calendar_activities' do
    subject { get :calendar_activities, username: user.username }

    it_behaves_like 'disabled when using an external authorization service'
  end
end
