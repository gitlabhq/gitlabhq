# frozen_string_literal: true

require 'spec_helper'

describe 'Merge request > User selects branches for new MR', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }

  def select_source_branch(branch_name)
    find('.js-source-branch', match: :first).click
    find('.js-source-branch-dropdown .dropdown-input-field').native.send_keys branch_name
    find('.js-source-branch-dropdown .dropdown-content a', text: branch_name, match: :first).click
  end

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it 'selects the source branch sha when a tag with the same name exists' do
    visit project_merge_requests_path(project)

    page.within '.content' do
      click_link 'New merge request'
    end
    expect(page).to have_content('Source branch')
    expect(page).to have_content('Target branch')

    first('.js-source-branch').click
    find('.js-source-branch-dropdown .dropdown-content a', match: :first).click

    expect(page).to have_content "b83d6e3"
  end

  it 'selects the target branch sha when a tag with the same name exists' do
    visit project_merge_requests_path(project)

    page.within '.content' do
      click_link 'New merge request'
    end

    expect(page).to have_content('Source branch')
    expect(page).to have_content('Target branch')

    first('.js-target-branch').click
    find('.js-target-branch-dropdown .dropdown-content a', text: 'v1.1.0', match: :first).click

    expect(page).to have_content "b83d6e3"
  end

  it 'generates a diff for an orphaned branch' do
    visit project_new_merge_request_path(project)

    select_source_branch('orphaned-branch')

    click_button "Compare branches"
    click_link "Changes"

    expect(page).to have_content "README.md"
    expect(page).to have_content "wm.png"

    fill_in "merge_request_title", with: "Orphaned MR test"
    click_button "Submit merge request"

    click_button "Check out branch"

    expect(page).to have_content 'git checkout -b "orphaned-branch" "origin/orphaned-branch"'
  end

  it 'allows filtering multiple dropdowns' do
    visit project_new_merge_request_path(project)

    first('.js-source-branch').click

    page.within '.js-source-branch-dropdown' do
      input = find('.dropdown-input-field')
      input.click
      input.send_keys('orphaned-branch')

      expect(page).to have_css('.dropdown-content li', count: 1)
    end

    first('.js-target-branch').click

    find('.js-target-branch-dropdown .dropdown-content li', match: :first)
    target_items = all('.js-target-branch-dropdown .dropdown-content li')

    expect(target_items.count).to be > 1
  end

  context 'when target project cannot be viewed by the current user' do
    it 'does not leak the private project name & namespace' do
      private_project = create(:project, :private, :repository)

      visit project_new_merge_request_path(project, merge_request: { target_project_id: private_project.id })

      expect(page).not_to have_content private_project.full_path
      expect(page).to have_content project.full_path
    end
  end

  context 'when source project cannot be viewed by the current user' do
    it 'does not leak the private project name & namespace' do
      private_project = create(:project, :private, :repository)

      visit project_new_merge_request_path(project, merge_request: { source_project_id: private_project.id })

      expect(page).not_to have_content private_project.full_path
      expect(page).to have_content project.full_path
    end
  end

  it 'populates source branch button' do
    visit project_new_merge_request_path(project, change_branches: true, merge_request: { target_branch: 'master', source_branch: 'fix' })

    expect(find('.js-source-branch')).to have_content('fix')
  end

  it 'allows to change the diff view' do
    visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: 'fix' })

    click_link 'Changes'

    expect(page).to have_css('a.btn.active', text: 'Inline')
    expect(page).not_to have_css('a.btn.active', text: 'Side-by-side')

    click_link 'Side-by-side'

    within '.merge-request' do
      expect(page).not_to have_css('a.btn.active', text: 'Inline')
      expect(page).to have_css('a.btn.active', text: 'Side-by-side')
    end
  end

  it 'does not allow non-existing branches' do
    visit project_new_merge_request_path(project, merge_request: { target_branch: 'non-exist-target', source_branch: 'non-exist-source' })

    expect(page).to have_content('The form contains the following errors')
    expect(page).to have_content('Source branch "non-exist-source" does not exist')
    expect(page).to have_content('Target branch "non-exist-target" does not exist')
  end

  context 'when a branch contains commits that both delete and add the same image' do
    it 'renders the diff successfully' do
      visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: 'deleted-image-test' })

      click_link "Changes"

      expect(page).to have_content "6049019_460s.jpg"
    end
  end

  # Isolates a regression (see #24627)
  it 'does not show error messages on initial form' do
    visit project_new_merge_request_path(project)
    expect(page).not_to have_selector('#error_explanation')
    expect(page).not_to have_content('The form contains the following error')
  end

  context 'when a new merge request has a pipeline' do
    let!(:pipeline) do
      create(:ci_pipeline, sha: project.commit('fix').id,
                           ref: 'fix',
                           project: project)
    end

    it 'shows pipelines for a new merge request' do
      visit project_new_merge_request_path(
        project,
        merge_request: { target_branch: 'master', source_branch: 'fix' })

      page.within('.merge-request') do
        click_link 'Pipelines'

        expect(page).to have_content "##{pipeline.id}"
      end
    end
  end

  context 'with special characters in branch names' do
    let(:create_branch_service) { ::Branches::CreateService.new(project, user) }

    it 'escapes quotes in branch names' do
      special_branch_name = '"with-quotes"'
      create_branch_service.execute(special_branch_name, 'add-pdf-file')

      visit project_new_merge_request_path(project)
      select_source_branch(special_branch_name)

      source_branch_input = find('[name="merge_request[source_branch]"]', visible: false)
      expect(source_branch_input.value).to eq special_branch_name
    end

    it 'does not escape unicode in branch names' do
      special_branch_name = 'ʕ•ᴥ•ʔ'
      create_branch_service.execute(special_branch_name, 'add-pdf-file')

      visit project_new_merge_request_path(project)
      select_source_branch(special_branch_name)

      click_button "Compare branches"

      expect(page).to have_button("Submit merge request")
    end
  end
end
