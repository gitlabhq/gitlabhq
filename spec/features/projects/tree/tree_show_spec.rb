require 'spec_helper'

feature 'Projects tree' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_master(user)
    sign_in(user)

    visit project_tree_path(project, 'master')
  end

  it 'renders tree table' do
    expect(page).to have_selector('.tree-item')
    expect(page).not_to have_selector('.label-lfs', text: 'LFS')
  end

  context 'LFS' do
    before do
      visit project_tree_path(project, File.join('master', 'files/lfs'))
    end

    it 'renders LFS badge on blob item' do
      expect(page).to have_selector('.label-lfs', text: 'LFS')
    end
  end
end
