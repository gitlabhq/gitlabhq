# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Multi-file editor upload file', :js, feature_category: :web_ide do
  include Features::WebIdeSpecHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:txt_file) { File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt') }
  let(:img_file) { File.join(Rails.root, 'spec', 'fixtures', 'dk.png') }

  before do
    stub_feature_flags(vscode_web_ide: false)

    project.add_maintainer(user)
    sign_in(user)

    visit project_tree_path(project, :master)

    wait_for_requests

    ide_visit_from_link
  end

  after do
    set_cookie('new_repo', 'false')
  end

  it 'uploads text file', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/415220' do
    wait_for_all_requests
    # make the field visible so capybara can use it
    execute_script('document.querySelector("#file-upload").classList.remove("hidden")')
    attach_file('file-upload', txt_file)

    expect(page).to have_selector('.multi-file-tab', text: 'doc_sample.txt')
    expect(find('.blob-editor-container .lines-content')['innerText']).to have_content(File.open(txt_file, &:readline).gsub!(/\s+/, ' '))
  end
end
