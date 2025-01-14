# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > Project owner creates a license file', :js, feature_category: :source_code_management do
  let_it_be(:project_maintainer) { create(:user) }
  let_it_be(:project) { create(:project, :repository, namespace: project_maintainer.namespace) }

  before do
    project.repository.delete_file(project_maintainer, 'LICENSE',
      message: 'Remove LICENSE', branch_name: 'master')
    sign_in(project_maintainer)
    visit project_path(project)
  end

  it 'project maintainer creates a license file manually from a template' do
    visit project_tree_path(project, project.repository.root_ref)
    find('.add-to-tree').click
    click_link 'New file'

    fill_in :file_name, with: 'LICENSE'

    select_template('MIT License')

    file_content = first('.file-editor')
    expect(file_content).to have_content('MIT License')
    expect(file_content).to have_content("Copyright (c) #{Time.zone.now.year} #{project.namespace.human_name}")

    click_button 'Commit changes'
    fill_in :commit_message, with: 'Add a LICENSE file', visible: true
    within_testid('commit-change-modal') do
      click_button 'Commit changes'
    end

    expect(page).to have_current_path(
      project_blob_path(project, 'master/LICENSE'), ignore_query: true)
    expect(page).to have_content('MIT License')
    expect(page).to have_content("Copyright (c) #{Time.zone.now.year} #{project.namespace.human_name}")
  end

  it 'project maintainer creates a license file from the "Add license" link' do
    click_link 'Add LICENSE'

    expect(page).to have_content('New file')
    expect(page).to have_current_path(
      project_new_blob_path(project, 'master'), ignore_query: true)
    expect(find('#file_name').value).to eq('LICENSE')

    select_template('MIT License')

    file_content = first('.file-editor')
    expect(file_content).to have_content('MIT License')
    expect(file_content).to have_content("Copyright (c) #{Time.zone.now.year} #{project.namespace.human_name}")

    click_button 'Commit changes'
    fill_in :commit_message, with: 'Add a LICENSE file', visible: true
    within_testid('commit-change-modal') do
      click_button 'Commit changes'
    end

    expect(page).to have_current_path(
      project_blob_path(project, 'master/LICENSE'), ignore_query: true)
    expect(page).to have_content('MIT License')
    expect(page).to have_content("Copyright (c) #{Time.zone.now.year} #{project.namespace.human_name}")
  end

  def select_template(template)
    within_testid('template-selector') do
      click_button 'Apply a template'
      find('.gl-new-dropdown-contents li', text: template).click
      wait_for_requests
    end
  end
end
