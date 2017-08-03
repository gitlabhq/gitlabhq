require 'spec_helper'

feature 'Projects > Members > Owner cannot request access to his project' do
  let(:project) { create(:project) }

  background do
    sign_in(project.owner)
    visit project_path(project)
  end

  scenario 'owner does not see the request access button' do
    expect(page).not_to have_content 'Request Access'
  end
end
