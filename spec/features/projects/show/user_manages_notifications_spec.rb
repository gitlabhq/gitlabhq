require 'spec_helper'

describe 'Projects > Show > User manages notifications', :js do
  let(:project) { create(:project, :public, :repository) }

  before do
    sign_in(project.owner)
    visit project_path(project)
  end

  it 'changes the notification setting' do
    first('.notifications-btn').click
    click_link 'On mention'

    page.within '#notifications-button' do
      expect(page).to have_content 'On mention'
    end
  end
end
