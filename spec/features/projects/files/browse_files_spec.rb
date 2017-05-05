require 'spec_helper'

feature 'user browses project', feature: true, js: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :master]
    login_with(user)
    visit namespace_project_tree_path(project.namespace, project, project.default_branch)
  end

  scenario "can see blame of '.gitignore'" do
    click_link ".gitignore"
    click_link 'Blame'

    expect(page).to have_content "*.rb"
    expect(page).to have_content "Dmitriy Zaporozhets"
    expect(page).to have_content "Initial commit"
  end

  scenario 'can see raw content of LFS pointer with LFS disabled' do
    allow_any_instance_of(Project).to receive(:lfs_enabled?).and_return(false)
    click_link 'files'
    click_link 'lfs'
    click_link 'lfs_object.iso'
    wait_for_ajax

    expect(page).not_to have_content 'Download (1.5 MB)'
    expect(page).to have_content 'version https://git-lfs.github.com/spec/v1'
    expect(page).to have_content 'oid sha256:91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897'
    expect(page).to have_content 'size 1575078'
  end
end
