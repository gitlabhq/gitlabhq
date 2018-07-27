require 'rails_helper'

describe 'Admin cohorts page' do
  before do
    sign_in(create(:admin))
  end

  it 'See users count per month' do
    2.times { create(:user) }

    visit admin_cohorts_path

    expect(page).to have_content("#{Time.now.strftime('%b %Y')} 3 0")
  end
end
