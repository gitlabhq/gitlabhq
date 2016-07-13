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
    it 'redirects to the login page when visiting the link from the body' do
      visit body_link

      expect(current_path).to eq new_user_session_path
      expect(issue.subscribed?(recipient)).to be_truthy
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
