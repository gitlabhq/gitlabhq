require 'spec_helper'

feature 'project import', feature: true, js: true do
  include Select2Helper

  let(:user) { create(:user) }
  let!(:namespace) { create(:namespace, name: "asd", owner: user) }
  background do
    login_as(user)
  end

  scenario 'user imports an exported project successfully' do
    visit new_project_path

    select2('asd', from: '#project_namespace_id')
    fill_in :project_path, with:'test-project-path', visible: true
    click_link 'GitLab project'

    expect(page).to have_content('GitLab export file')
    expect(URI.parse(current_url).query).to eq('namespace_id=asd&path=test-project-path')
  end
end
