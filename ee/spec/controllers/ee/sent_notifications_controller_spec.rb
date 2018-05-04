require 'rails_helper'

describe SentNotificationsController do
  let(:user) { create(:user) }

  context 'Unsubscribing from an epic' do
    let(:epic) do
      create(:epic, author: user) do |epic|
        epic.subscriptions.create(user: user, project: nil, subscribed: true)
      end
    end
    let(:sent_notification) { create(:sent_notification, project: nil, noteable: epic, recipient: user) }

    before do
      sign_in(user)
      get(:unsubscribe, id: sent_notification.reply_key)
    end

    it 'unsubscribes the user' do
      expect(epic.subscribed?(user)).to be_falsey
    end

    it 'sets the flash message' do
      expect(controller).to set_flash[:notice].to(/unsubscribed/)
    end

    it 'redirects to the merge request page' do
      expect(response)
        .to redirect_to(group_epic_path(epic.group, epic))
    end
  end
end
