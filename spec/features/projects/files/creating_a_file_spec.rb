require 'spec_helper'

feature 'User wants to create a file', feature: true do
  include WaitForAjax

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  background do
    project.team << [user, :master]
    login_as user
    visit namespace_project_new_blob_path(project.namespace, project, project.default_branch)
  end

  def submit_new_file(options)
    file_name = find('#file_name')
    file_name.set options[:file_name] || 'README.md'

    file_content = find('#file-content')
    file_content.set options[:file_content] || 'Some content'

    click_button 'Commit Changes'
  end

  scenario 'file name contains Chinese characters' do
    submit_new_file(file_name: '测试.md')
    expect(page).to have_content 'The file has been successfully created.'
  end

  scenario 'directory name contains Chinese characters' do
    submit_new_file(file_name: '中文/测试.md')
    expect(page).to have_content 'The file has been successfully created.'
  end

  scenario 'file name contains invalid characters' do
    submit_new_file(file_name: '\\')
    expect(page).to have_content 'Your changes could not be committed, because the file name can contain only'
  end

  scenario 'file name contains directory traversal' do
    submit_new_file(file_name: '../README.md')
    expect(page).to have_content 'Your changes could not be committed, because the file name cannot include directory traversal.'
  end
end
