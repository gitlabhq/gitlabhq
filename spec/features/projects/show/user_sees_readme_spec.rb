# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User sees README' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :public) }

  it 'shows the project README', :js do
    visit project_path(project)
    wait_for_requests

    page.within('.readme-holder') do
      expect(page).to have_content 'testme'
    end
  end
end
