require 'spec_helper'

describe Admin::SpamLogsController do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let!(:first_spam) { create(:spam_log, user: user) }
  let!(:second_spam) { create(:spam_log, user: user) }

  before do
    sign_in(admin)
  end

  describe '#index' do
    it 'lists all spam logs' do
      get :index

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe '#destroy' do
    it 'removes only the spam log when removing log' do
      expect { delete :destroy, id: first_spam.id }.to change { SpamLog.count }.by(-1)
      expect(User.find(user.id)).to be_truthy
      expect(response).to have_gitlab_http_status(200)
    end

    it 'removes user and his spam logs when removing the user' do
      delete :destroy, id: first_spam.id, remove_user: true

      expect(flash[:notice]).to eq "User #{user.username} was successfully removed."
      expect(response).to have_gitlab_http_status(302)
      expect(SpamLog.count).to eq(0)
      expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#mark_as_ham' do
    before do
      allow_any_instance_of(AkismetService).to receive(:submit_ham).and_return(true)
    end
    it 'submits the log as ham' do
      post :mark_as_ham, id: first_spam.id

      expect(response).to have_gitlab_http_status(302)
      expect(SpamLog.find(first_spam.id).submitted_as_ham).to be_truthy
    end
  end
end
