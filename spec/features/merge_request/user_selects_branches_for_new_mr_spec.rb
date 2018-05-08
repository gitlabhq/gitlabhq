require 'rails_helper'

describe 'Merge request > User selects branches for new MR', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }

  before do
    project.add_master(user)
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
    find('.dropdown-source-branch .dropdown-content a', match: :first).click

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
    find('.dropdown-target-branch .dropdown-content a', text: 'v1.1.0', match: :first).click

    expect(page).to have_content "b83d6e3"
  end

  it 'generates a diff for an orphaned branch' do
    visit project_merge_requests_path(project)

    page.within '.content' do
      click_link 'New merge request'
    end
    expect(page).to have_content('Source branch')
    expect(page).to have_content('Target branch')

    find('.js-source-branch', match: :first).click
    find('.dropdown-source-branch .dropdown-content a', text: 'orphaned-branch', match: :first).click

    click_button "Compare branches"
    click_link "Changes"

    expect(page).to have_content "README.md"
    expect(page).to have_content "wm.png"

    fill_in "merge_request_title", with: "Orphaned MR test"
    click_button "Submit merge request"

    click_button "Check out branch"

    expect(page).to have_content 'git checkout -b orphaned-branch origin/orphaned-branch'
  end

  it 'allows filtering multiple dropdowns' do
    visit project_new_merge_request_path(project)

    first('.js-source-branch').click

    input = find('.dropdown-source-branch .dropdown-input-field')
    input.click
    input.send_keys('orphaned-branch')

    find('.dropdown-source-branch .dropdown-content li', match: :first)
    source_items = all('.dropdown-source-branch .dropdown-content li')

    expect(source_items.count).to eq(1)

    first('.js-target-branch').click

    find('.dropdown-target-branch .dropdown-content li', match: :first)
    target_items = all('.dropdown-target-branch .dropdown-content li')

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
        wait_for_requests

        expect(page).to have_content "##{pipeline.id}"
      end
    end
  end
end
