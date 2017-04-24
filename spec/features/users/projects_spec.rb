require 'spec_helper'

describe 'Projects tab on a user profile', :feature, :js do
  let(:user) { create(:user) }
  let!(:project) { create(:empty_project, namespace: user.namespace) }
  let!(:project2) { create(:empty_project, namespace: user.namespace) }

  before do
    allow(Project).to receive(:default_per_page).and_return(1)

    login_as(user)

    visit user_path(user)

    page.within('.user-profile-nav') do
      click_link('Personal projects')
    end

    wait_for_ajax
  end

  it 'paginates results' do
    expect(page).to have_content(project2.name)

    click_link('Next')

    expect(page).to have_content(project.name)
  end
end
