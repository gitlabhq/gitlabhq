require 'spec_helper'

feature 'Tags sort dropdown', :feature do
  let(:project) { create(:project) }

  before do
    login_as(:admin)

    visit namespace_project_tags_path(project.namespace, project)
  end

  it 'defaults sort dropdown to last updated' do
    expect(page).to have_button('Last updated')
  end
end
