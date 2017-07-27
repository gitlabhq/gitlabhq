require 'spec_helper'

feature 'User wants to create a file', feature: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  background do
    project.team << [user, :master]
    sign_in user
    visit project_new_blob_path(project, project.default_branch)
  end

  def submit_new_file(options)
    file_name = find('#file_name')
    file_name.set options[:file_name] || 'README.md'

    file_content = find('#file-content')
    file_content.set options[:file_content] || 'Some content'

    click_button 'Commit changes'
  end

  scenario 'file name contains Chinese characters' do
    submit_new_file(file_name: '测试.md')
    expect(page).to have_content 'The file has been successfully created.'
  end

  scenario 'directory name contains Chinese characters' do
    submit_new_file(file_name: '中文/测试.md')
    expect(page).to have_content 'The file has been successfully created'
  end

  scenario 'file name contains directory traversal' do
    submit_new_file(file_name: '../README.md')
    expect(page).to have_content 'Path cannot include directory traversal'
  end
end
