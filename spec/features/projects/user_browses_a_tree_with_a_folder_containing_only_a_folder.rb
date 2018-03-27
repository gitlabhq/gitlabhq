require 'spec_helper'

# This is a regression test for https://gitlab.com/gitlab-org/gitlab-ce/issues/37569
describe 'User browses a tree with a folder containing only a folder' do
  let(:project) { create(:project, :empty_repo) }
  let(:user) { project.creator }

  before do
    # We need to disable the tree.flat_path provided by Gitaly to reproduce the issue
    allow(Gitlab::GitalyClient).to receive(:feature_enabled?).and_return(false)

    project.repository.create_dir(user, 'foo/bar', branch_name: 'master', message: 'Add the foo/bar folder')
    sign_in(user)
    visit(project_tree_path(project, project.repository.root_ref))
  end

  it 'shows the nested folder on a single row' do
    expect(page).to have_content('foo/bar')
  end
end
