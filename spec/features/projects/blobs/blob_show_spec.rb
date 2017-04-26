require 'spec_helper'

feature 'File blob', feature: true do
  include TreeHelper

  let(:project) { create(:project, :public, :test_repo) }
  let(:merge_request) { create(:merge_request, source_project: project, source_branch: 'feature', target_branch: 'master') }
  let(:branch) { 'master' }
  let(:file_path) { project.repository.ls_files(project.repository.root_ref)[1] }

  context 'anonymous' do
    context 'from blob file path' do
      before do
        visit namespace_project_blob_path(project.namespace, project, tree_join(branch, file_path))
      end

      it 'updates content' do
        expect(page).to have_link  'Edit'
      end
    end
  end
end
