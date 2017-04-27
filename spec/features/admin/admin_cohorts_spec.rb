require 'rails_helper'

feature 'Admin cohorts page', feature: true do
  before do
    login_as :admin
  end

  scenario 'See users count per month' do
    2.times { create(:user) }

    visit admin_cohorts_path

    expect(page).to have_content("#{Time.now.strftime('%b %Y')} 3 0")
  end
end
