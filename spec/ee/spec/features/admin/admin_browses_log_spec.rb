require 'spec_helper'

describe 'Admin browses logs' do
  before do
    sign_in(create(:admin))
  end

  it 'shows available log files' do
    visit admin_logs_path

    expect(page).to have_link 'geo.log'
  end
end
