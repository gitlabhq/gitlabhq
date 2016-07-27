require 'spec_helper'

feature 'Merge Request versions', js: true, feature: true do
  before do
    login_as :admin
    merge_request = create(:merge_request, importing: true)
    merge_request.merge_request_diffs.create(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9')
    merge_request.merge_request_diffs.create(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e')
    project = merge_request.source_project
    visit diffs_namespace_project_merge_request_path(project.namespace, project, merge_request)
  end

  it 'show the latest version of the diff' do
    page.within '.mr-version-switch' do
      expect(page).to have_content 'Version: latest'
    end

    expect(page).to have_content '8 changed files'
  end

  describe 'switch between versions' do
    before do
      page.within '.mr-version-switch' do
        find('.btn-link').click
        #find('a', text: '6f6d7e7e').click
        click_link '6f6d7e7e'
      end
    end

    it 'should show older version' do
      page.within '.mr-version-switch' do
        expect(page).to have_content 'Version: 6f6d7e7e'
      end

      expect(page).to have_content '5 changed files'
    end
  end
end
