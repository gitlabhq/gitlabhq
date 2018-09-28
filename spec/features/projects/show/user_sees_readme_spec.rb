require 'spec_helper'

describe 'Projects > Show > User sees README' do
  set(:user) { create(:user) }

  set(:project) { create(:project, :repository, :public) }

  it 'shows the project README', :js do
    visit project_path(project)
    wait_for_requests

    page.within('.readme-holder') do
      expect(page).to have_content 'testme'
    end
  end
end
