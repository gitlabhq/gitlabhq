require 'spec_helper'

feature 'Balsamiq preview', :feature, :js do
  include TreeHelper

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:branch) { 'add-balsamiq-file' }
  let(:path) { 'files/images/balsamiq.bmpr' }
  let(:file_content) { find('.file-content') }

  before do
    project.add_master(user)
    login_as user
    visit namespace_project_blob_path(project.namespace, project, tree_join(branch, path))
  end

  it 'should show a loading icon' do
    expect(file_content).to have_selector('.loading')
  end

  it 'should show a viewer container' do
    expect(page).to have_selector('.balsamiq-viewer')
  end
end
