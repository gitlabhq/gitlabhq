require 'spec_helper'

feature 'Balsamiq preview', :feature, :js do
  include TreeHelper

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:branch) { 'add-balsamiq-file' }
  let(:path) { 'files/images/balsamiq.bmpr' }

  before do
    project.add_master(user)

    login_as user

    p namespace_project_blob_path(project.namespace, project, tree_join(branch, path))

    visit namespace_project_blob_path(project.namespace, project, tree_join(branch, path))
  end

  it 'should' do
    screenshot_and_open_image
  end
end
