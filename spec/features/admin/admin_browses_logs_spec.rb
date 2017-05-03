require 'spec_helper'

describe 'Admin browses logs' do
  before do
    login_as :admin
  end

  it 'shows available log files' do
    visit admin_logs_path

    expect(page).to have_content 'test.log'
    expect(page).to have_content 'githost.log'
    expect(page).to have_content 'application.log'
  end
end
