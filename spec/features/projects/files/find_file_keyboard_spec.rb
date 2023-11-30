# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > Find file keyboard shortcuts', :js, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:user) { project.first_owner }

  before do
    sign_in user

    visit project_find_file_path(project, project.repository.root_ref)

    wait_for_requests
  end

  it 'opens file when pressing enter key' do
    fill_in 'file_find', with: 'CHANGELOG'

    find('#file_find').native.send_keys(:enter)

    expect(page).to have_selector('.blob-content-holder')

    page.within('.js-file-title') do
      expect(page).to have_content('CHANGELOG')
    end
  end

  it 'navigates files with arrow keys' do
    fill_in 'file_find', with: 'application.'

    find('#file_find').native.send_keys(:down)
    find('#file_find').native.send_keys(:enter)

    expect(page).to have_selector('.blob-content-holder')

    page.within('.js-file-title') do
      expect(page).to have_content('application.js')
    end
  end
end
