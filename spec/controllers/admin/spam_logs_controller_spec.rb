require 'spec_helper'

describe Admin::SpamLogsController do
  let(:admin)    { create(:admin) }
  let(:spam_log) { create(:spam_log, user: admin) }

  before do
    sign_in(admin)
  end

  describe '#index' do
    it 'lists all spam logs' do
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe '#destroy' do
    it 'destroys just spam log' do
      user = spam_log.user
      delete :destroy, id: spam_log.id

      expect(SpamLog.all.count).to eq(0)
      expect(User.find(user.id)).to be_truthy
      expect(response.status).to eq(302)
    end

    it 'destroys user and his spam logs' do
      user = spam_log.user
      delete :destroy, id: spam_log.id, remove_user: true

      expect(SpamLog.all.count).to eq(0)
      expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response.status).to eq(302)
    end

    it 'destroys user and his spam logs with JSON format' do
      user = spam_log.user
      delete :destroy, id: spam_log.id, remove_user: true, format: :json

      expect(SpamLog.all.count).to eq(0)
      expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(JSON.parse(response.body)).to eq({})
      expect(response.status).to eq(200)
    end
  end
end
