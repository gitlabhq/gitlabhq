require 'spec_helper'

feature 'Multi-file editor upload file', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:txt_file) { File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt') }
  let(:img_file) { File.join(Rails.root, 'spec', 'fixtures', 'dk.png') }

  before do
    project.add_master(user)
    sign_in(user)

    visit project_tree_path(project, :master)

    wait_for_requests

    click_link('Web IDE')

    wait_for_requests
  end

  after do
    set_cookie('new_repo', 'false')
  end

  it 'uploads text file' do
    find('.add-to-tree').click

    # make the field visible so capybara can use it
    execute_script('document.querySelector("#file-upload").classList.remove("hidden")')
    attach_file('file-upload', txt_file)

    find('.add-to-tree').click

    expect(page).to have_selector('.multi-file-tab', text: 'doc_sample.txt')
    expect(find('.blob-editor-container .lines-content')['innerText']).to have_content(File.open(txt_file, &:readline))
  end
end
