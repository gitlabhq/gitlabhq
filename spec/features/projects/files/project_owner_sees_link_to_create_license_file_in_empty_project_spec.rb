# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > Project owner sees a link to create a license file in empty project', :js,
  feature_category: :source_code_management do
  include Features::WebIdeSpecHelpers

  let(:project) { create(:project_empty_repo) }
  let(:project_maintainer) { project.first_owner }

  before do
    sign_in(project_maintainer)
  end

  it 'allows project maintainer creates a license file from a template in Web IDE' do
    visit project_path(project)
    click_on 'Add LICENSE'

    expect(page).to have_current_path("/-/ide/project/#{project.full_path}/edit/master/-/LICENSE", ignore_query: true)

    within_web_ide do
      expect(page).to have_text('LICENSE')
    end
  end
end
