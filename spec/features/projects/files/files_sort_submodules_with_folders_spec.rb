# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User views files page', feature_category: :source_code_management do
  let(:project) { create(:forked_project_with_submodules) }
  let(:user) { project.first_owner }

  before do
    sign_in user
    visit project_tree_path(project, project.repository.root_ref)
  end

  it 'user sees folders and submodules sorted together, followed by files', :js do
    rows = all('th.tree-item-file-name').map(&:text)
    tree = project.repository.tree

    folders = tree.trees.map(&:name)
    files = tree.blobs.map(&:name)
    submodules = tree.submodules.map do |submodule|
      "#{submodule.name}\n@ #{submodule.id[0..7]}"
    end

    sorted_titles = (folders + submodules).sort + files

    expect(rows).to eq(sorted_titles)
  end
end
