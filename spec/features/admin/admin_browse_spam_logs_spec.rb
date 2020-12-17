# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin browse spam logs' do
  let!(:spam_log) { create(:spam_log, description: 'abcde ' * 20) }

  before do
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  it 'browse spam logs' do
    visit admin_spam_logs_path

    expect(page).to have_content('Spam Logs')
    expect(page).to have_content(spam_log.source_ip)
    expect(page).to have_content(spam_log.noteable_type)
    expect(page).to have_content('N')
    expect(page).to have_content(spam_log.title)
    expect(page).to have_content("#{spam_log.description[0...97]}...")
    expect(page).to have_link('Remove user')
    expect(page).to have_link('Block user')
  end
end
