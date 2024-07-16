# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin browse spam logs', feature_category: :shared do
  let!(:spam_log) { create(:spam_log, description: 'abcde ' * 20) }
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  it 'browse spam logs', :js do
    visit admin_spam_logs_path

    expect(page).to have_content('Spam logs')
    expect(page).to have_content(spam_log.source_ip)
    expect(page).to have_content(spam_log.noteable_type)
    expect(page).not_to have_content('Recaptcha verified')
    expect(page).to have_content(spam_log.title)
    expect(page).to have_content(spam_log.description[0...97].to_s)
    click_button 'More actions'
    expect(page).to have_link('Remove user')
    expect(page).to have_link('Block user')
    expect(page).to have_link('Trust user')
  end

  it 'passes axe automated accessibility testing', :js do
    visit admin_spam_logs_path
    expect(page).to be_axe_clean.within('.table').skipping :'link-in-text-block'
  end

  it 'does not perform N+1 queries' do
    control_queries = ActiveRecord::QueryRecorder.new { visit admin_spam_logs_path }
    create(:spam_log)

    expect { visit admin_spam_logs_path }.not_to exceed_query_limit(control_queries)
  end

  context 'when user is trusted' do
    before do
      UserCustomAttribute.set_trusted_by(user: spam_log.user, trusted_by: admin)
    end

    it 'allows admin to untrust the user' do
      visit admin_spam_logs_path
      expect(page).to have_link('Untrust user')
    end
  end
end
