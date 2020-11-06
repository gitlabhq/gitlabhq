# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > Project owner sees a link to create a license file in empty project', :js do
  include WebIdeSpecHelpers

  let(:project) { create(:project_empty_repo) }
  let(:project_maintainer) { project.owner }

  before do
    sign_in(project_maintainer)
  end

  it 'allows project maintainer creates a license file from a template in Web IDE' do
    visit project_path(project)
    click_on 'Add LICENSE'

    expect(current_path).to eq("/-/ide/project/#{project.full_path}/edit/master/-/LICENSE")

    expect(page).to have_selector('.qa-file-templates-bar')

    select_template('MIT License')

    expect(ide_editor_value).to have_content('MIT License')
    expect(ide_editor_value).to have_content("Copyright (c) #{Time.now.year} #{project.namespace.human_name}")

    ide_commit

    expect(current_path).to eq("/-/ide/project/#{project.full_path}/tree/master/-/LICENSE/")

    expect(page).to have_content('All changes are committed')

    license_file = project.repository.blob_at('master', 'LICENSE').data
    expect(license_file).to have_content('MIT License')
    expect(license_file).to have_content("Copyright (c) #{Time.now.year} #{project.namespace.human_name}")
  end

  def select_template(template)
    click_button 'Choose a template...'
    click_button template
    wait_for_requests
  end
end
