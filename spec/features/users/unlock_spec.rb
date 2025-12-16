# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User unlock', feature_category: :system_access do
  include EmailHelpers

  let_it_be(:user) { create(:user) }

  it 'sends unlock instructions with working link' do
    perform_enqueued_jobs do
      user.lock_access!
    end

    mail = find_email_for(user.email)
    expect(mail.subject).to eq('Unlock instructions')

    body = Nokogiri::HTML::DocumentFragment.parse(mail.body.parts.last.to_s)
    unlock_link = body.css('#cta a').attribute('href').value
    expect { visit unlock_link }.to change { user.reload.access_locked? }.from(true).to(false)

    expect(page).to have_content('Your account has been unlocked successfully.')
  end

  context 'when devise_email_organization_routes FF is disabled' do
    before do
      stub_feature_flags(devise_email_organization_routes: false)
    end

    it 'sends unlock instructions with working link' do
      perform_enqueued_jobs do
        user.lock_access!
      end

      mail = find_email_for(user.email)
      expect(mail.subject).to eq('Unlock instructions')

      body = Nokogiri::HTML::DocumentFragment.parse(mail.body.parts.last.to_s)
      unlock_link = body.css('#cta a').attribute('href').value
      expect(unlock_link).not_to include("/o/#{user.organization.path}")

      expect { visit unlock_link }.to change { user.reload.access_locked? }.from(true).to(false)

      expect(page).to have_content('Your account has been unlocked successfully.')
    end
  end
end
