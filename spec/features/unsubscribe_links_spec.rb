require 'spec_helper'

describe 'Unsubscribe links', feature: true do
  include Warden::Test::Helpers

  let(:recipient) { create(:user) }
  let(:author) { create(:user) }
  let(:project) { create(:empty_project, :public) }
  let(:params) { { title: 'A bug!', description: 'Fix it!', assignee: recipient } }
  let(:issue) { Issues::CreateService.new(project, author, params).execute }

  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:body) { Capybara::Node::Simple.new(mail.default_part_body.to_s) }
  let(:header_link) { mail.header['List-Unsubscribe'] }
  let(:body_link) { body.find_link('unsubscribe')['href'] }

  before do
    perform_enqueued_jobs { issue }
  end

  context 'when logged out' do
    context 'when visiting the link from the body' do
      it 'shows the unsubscribe confirmation page and redirects to root path when confirming' do
        visit body_link

        expect(current_path).to eq unsubscribe_sent_notification_path(SentNotification.last)
        expect(page).to have_text(%(Unsubscribe from issue #{issue.title} (#{issue.to_reference})))
        expect(page).to have_text(%(Are you sure you want to unsubscribe from issue #{issue.title} (#{issue.to_reference})?))
        expect(issue.subscribed?(recipient)).to be_truthy

        click_link 'Unsubscribe'

        expect(issue.subscribed?(recipient)).to be_falsey
        expect(current_path).to eq new_user_session_path
      end

      it 'shows the unsubscribe confirmation page and redirects to root path when canceling' do
        visit body_link

        expect(current_path).to eq unsubscribe_sent_notification_path(SentNotification.last)
        expect(issue.subscribed?(recipient)).to be_truthy

        click_link 'Cancel'

        expect(issue.subscribed?(recipient)).to be_truthy
        expect(current_path).to eq new_user_session_path
      end
    end

    it 'unsubscribes from the issue when visiting the link from the header' do
      visit header_link

      expect(page).to have_text('unsubscribed')
      expect(issue.subscribed?(recipient)).to be_falsey
    end
  end

  context 'when logged in' do
    before { login_as(recipient) }

    it 'unsubscribes from the issue when visiting the link from the email body' do
      visit body_link

      expect(page).to have_text('unsubscribed')
      expect(issue.subscribed?(recipient)).to be_falsey
    end

    it 'unsubscribes from the issue when visiting the link from the header' do
      visit header_link

      expect(page).to have_text('unsubscribed')
      expect(issue.subscribed?(recipient)).to be_falsey
    end
  end
end
