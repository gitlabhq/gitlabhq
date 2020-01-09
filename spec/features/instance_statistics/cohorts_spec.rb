# frozen_string_literal: true

require 'spec_helper'

describe 'Cohorts page' do
  before do
    sign_in(create(:admin))

    stub_application_setting(usage_ping_enabled: true)
  end

  it 'See users count per month' do
    create_list(:user, 2)

    visit instance_statistics_cohorts_path

    expect(page).to have_content("#{Time.now.strftime('%b %Y')} 3 0")
  end
end
