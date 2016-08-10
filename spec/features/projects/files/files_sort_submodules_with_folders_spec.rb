require 'spec_helper'

feature 'User views files page', feature: true do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:forked_project_with_submodules) }

  before do
    project.team << [user, :master]
    login_as user
    visit namespace_project_tree_path(project.namespace, project, project.repository.root_ref)
  end

  scenario 'user sees folders and submodules sorted together, followed by files' do
    rows = all('td.tree-item-file-name').map(&:text)
    tree = project.repository.tree

    folders = tree.trees.map(&:name)
    files = tree.blobs.map(&:name)
    submodules = tree.submodules.map do |submodule|
      submodule.name + " @ " + submodule.id[0..7]
    end

    sorted_titles = (folders + submodules).sort + files

    expect(rows).to eq(sorted_titles)
  end
end
