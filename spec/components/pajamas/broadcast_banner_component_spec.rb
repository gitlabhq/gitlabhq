# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pajamas::BroadcastBannerComponent, :aggregate_failures, type: :component, feature_category: :notifications do
  before do
    render_inline described_class.new(message: message,
      id: id,
      theme: theme,
      dismissable: dismissable,
      expire_date: expire_date,
      cookie_key: cookie_key,
      dismissal_path: dismissal_path,
      button_testid: button_testid,
      banner: banner
    )
  end

  let(:message) { '_message_' }
  let(:id) { '_99_' }
  let(:theme) { '_theme_' }
  let(:dismissable) { true }
  let(:expire_date) { Time.now.iso8601 }
  let(:cookie_key) { '_cookie_key_' }
  let(:dismissal_path) { '/-/my-path' }
  let(:button_testid) { 'my-close-button' }
  let(:banner) { true }

  it 'sets the correct classes' do
    expect(page).to have_selector(".js-broadcast-notification-#{id}")
    expect(page).to have_selector(".#{theme}")
  end

  it 'contains a screen reader message' do
    expect(page).to have_selector('.gl-sr-only', text: _('Admin message'))
  end

  it 'sets the message' do
    expect(page).to have_content(message)
  end

  context 'when dismissable is true' do
    it 'display close button' do
      expect(page).to have_selector('button.js-dismiss-current-broadcast-notification')
      expect(page).to have_selector("button[data-id='#{id}']")
      expect(page).to have_selector("button[data-expire-date='#{expire_date}']")
      expect(page).to have_selector("button[data-dismissal-path='#{dismissal_path}']")
      expect(page).to have_selector("button[data-cookie-key='#{cookie_key}']")
    end

    context 'when dismissal_path is no set' do
      let(:dismissal_path) { nil }

      it 'display close button' do
        expect(page).not_to have_selector("button[data-dismissal-path='#{dismissal_path}']")
      end
    end
  end

  context 'when dismissable is false' do
    let(:dismissable) { false }

    it 'does not display close button' do
      expect(page).not_to have_selector('button.js-dismiss-current-broadcast-notification')
    end
  end

  it 'sets the button testid' do
    expect(page).to have_selector("button[data-testid='#{button_testid}']")
  end

  it 'adds data-broadcast-banner when banner is true' do
    expect(page).to have_selector("[data-broadcast-banner]")
  end
end
