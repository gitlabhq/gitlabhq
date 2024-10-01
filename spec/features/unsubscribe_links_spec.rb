# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Unsubscribe links', :sidekiq_inline, feature_category: :shared do
  include Warden::Test::Helpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:author) { create(:user, reporter_of: project) }
  let_it_be(:recipient) { create(:user) }

  let(:params) { { title: 'A bug!', description: 'Fix it!', assignee_ids: [recipient.id] } }
  let(:issue) { Issues::CreateService.new(container: project, current_user: author, params: params).execute[:issue] }

  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:body) { Capybara::Node::Simple.new(mail.default_part_body.to_s) }
  let(:header_link) { mail.header['List-Unsubscribe'].to_s[1..-2] } # Strip angle brackets
  let(:link) { body.find_link('Unsubscribe')['href'] }

  before do
    perform_enqueued_jobs { issue }
  end

  context 'when logged out' do
    shared_examples 'unsubscribes via confirmation page' do
      it 'shows the unsubscribe confirmation page and redirects to root path when confirming' do
        visit link

        expect(page).to have_current_path unsubscribe_sent_notification_path(SentNotification.last), ignore_query: true
        expect(page).to have_text(%(Unsubscribe from issue))
        expect(page).to have_text(%(Are you sure you want to unsubscribe from the issue: #{issue.title} (#{issue.to_reference})?))
        expect(issue.subscribed?(recipient, project)).to be_truthy

        click_link 'Unsubscribe'

        expect(issue.subscribed?(recipient, project)).to be_falsey
        expect(page).to have_current_path new_user_session_path, ignore_query: true
      end

      it 'shows the unsubscribe confirmation page and redirects to root path when canceling' do
        visit link

        expect(page).to have_current_path unsubscribe_sent_notification_path(SentNotification.last), ignore_query: true
        expect(issue.subscribed?(recipient, project)).to be_truthy

        click_link 'Cancel'

        expect(issue.subscribed?(recipient, project)).to be_truthy
        expect(page).to have_current_path new_user_session_path, ignore_query: true
      end
    end

    context 'when visiting the link from the body' do
      it_behaves_like 'unsubscribes via confirmation page'
    end

    context 'when visiting the link from the header' do
      let(:link) { header_link }

      # It's the same link for both body and header.
      # To comply with RFC8058 the header link needs to be
      # called via a POST request to directly unsubscribe.
      it_behaves_like 'unsubscribes via confirmation page'
    end
  end

  context 'when logged in' do
    before do
      sign_in(recipient)
    end

    it 'unsubscribes from the issue when visiting the link from the email body' do
      visit link

      expect(page).to have_text('unsubscribed')
      expect(issue.subscribed?(recipient, project)).to be_falsey
    end

    it 'unsubscribes from the issue when visiting the link from the header' do
      visit header_link

      expect(page).to have_text('unsubscribed')
      expect(issue.subscribed?(recipient, project)).to be_falsey
    end
  end
end
