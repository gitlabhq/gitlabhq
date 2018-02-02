require 'spec_helper'

describe Admin::GitalyServersController do
  describe '#index' do
    before do
      sign_in(create(:admin))
    end

    it 'shows the gitaly servers page' do
      get :index

      expect(response).to have_gitlab_http_status(200)
    end
  end
end
