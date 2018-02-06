class Spinach::Features::ProjectCommits < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include SharedDiffNote
  include RepoHelpers

  step 'I see project commits' do
    commit = @project.repository.commit
    expect(page).to have_content(@project.name)
    expect(page).to have_content(commit.message[0..20])
    expect(page).to have_content(commit.short_id)
  end

  step 'I click atom feed link' do
    click_link "Commits feed"
  end

  step 'I see commits atom feed' do
    commit = @project.repository.commit
    expect(response_headers['Content-Type']).to have_content("application/atom+xml")
    expect(body).to have_selector("title", text: "#{@project.name}:master commits")
    expect(body).to have_selector("author email", text: commit.author_email)
    expect(body).to have_selector("entry summary", text: commit.description[0..10].delete("\r\n"))
  end

  step 'I click on tag link' do
    click_link "Tag"
  end

  step 'I see commit SHA pre-filled' do
    expect(page).to have_selector("input[value='#{sample_commit.id}']")
  end

  step 'I click on commit link' do
    visit project_commit_path(@project, sample_commit.id)
  end

  step 'I see commit info' do
    expect(page).to have_content sample_commit.message
    expect(page).to have_content "Showing #{sample_commit.files_changed_count} changed files"
  end

  step 'I fill compare fields with branches' do
    select_using_dropdown('from', 'feature')
    select_using_dropdown('to', 'master')

    click_button 'Compare'
  end

  step 'I fill compare fields with refs' do
    select_using_dropdown('from', sample_commit.parent_id, true)
    select_using_dropdown('to', sample_commit.id, true)

    click_button "Compare"
  end

  step 'I unfold diff' do
    @diff = first('.js-unfold')
    @diff.click
    sleep 2
  end

  step 'I should see additional file lines' do
    page.within @diff.query_scope do
      expect(first('.new_line').text).not_to have_content "..."
    end
  end

  step 'I see compared refs' do
    expect(page).to have_content "Commits (1)"
    expect(page).to have_content "Showing 2 changed files"
  end

  step 'I visit commits list page for feature branch' do
    visit project_commits_path(@project, 'feature', { limit: 5 })
  end

  step 'I see feature branch commits' do
    commit = @project.repository.commit('0b4bc9a')
    expect(page).to have_content(@project.name)
    expect(page).to have_content(commit.message[0..12])
    expect(page).to have_content(commit.short_id)
  end

  step 'project have an open merge request' do
    create(:merge_request,
           title: 'Feature',
           source_project: @project,
           source_branch: 'feature',
           target_branch: 'master',
           author: @project.users.first
          )
  end

  step 'I click the "Compare" tab' do
    click_link('Compare')
  end

  step 'I fill compare fields with branches' do
    select_using_dropdown('from', 'master')
    select_using_dropdown('to', 'feature')

    click_button 'Compare'
  end

  step 'I see compared branches' do
    expect(page).to have_content 'Commits (1)'
    expect(page).to have_content 'Showing 1 changed file with 5 additions and 0 deletions'
  end

  step 'I see button to create a new merge request' do
    expect(page).to have_link 'Create merge request'
  end

  step 'I should not see button to create a new merge request' do
    expect(page).not_to have_link 'Create merge request'
  end

  step 'I should see button to the merge request' do
    merge_request = MergeRequest.find_by(title: 'Feature')
    expect(page).to have_link "View open merge request", href: project_merge_request_path(@project, merge_request)
  end

  step 'I see breadcrumb links' do
    expect(page).to have_selector('ul.breadcrumb')
    expect(page).to have_selector('ul.breadcrumb a', count: 4)
  end

  step 'I see commits stats' do
    expect(page).to have_content 'Top 50 Committers'
    expect(page).to have_content 'Committers'
    expect(page).to have_content 'Total commits'
    expect(page).to have_content 'Authors'
  end

  step 'I visit a commit with an image that changed' do
    visit project_commit_path(@project, sample_image_commit.id)
  end

  step 'The diff links to both the previous and current image' do
    links = page.all('.file-actions a')
    expect(links[0]['href']).to match %r{blob/#{sample_image_commit.old_blob_id}}
    expect(links[1]['href']).to match %r{blob/#{sample_image_commit.new_blob_id}}
  end

  step 'I see inline diff button' do
    expect(page).to have_content "Inline"
  end

  step 'I click side-by-side diff button' do
    find('#parallel-diff-btn').click
  end

  step 'commit has ci status' do
    @project.enable_ci
    @pipeline = create(:ci_pipeline, project: @project, sha: sample_commit.id)
    create(:ci_build, pipeline: @pipeline)
  end

  step 'repository contains ".gitlab-ci.yml" file' do
    allow_any_instance_of(Ci::Pipeline).to receive(:ci_yaml_file).and_return(String.new)
  end

  step 'I see commit ci info' do
    expect(page).to have_content "Pipeline ##{@pipeline.id} pending"
  end

  step 'I search "submodules" commits' do
    fill_in 'commits-search', with: 'submodules'
  end

  step 'I should see only "submodules" commits' do
    expect(page).to have_content "More submodules"
    expect(page).not_to have_content "Change some files"
  end

  def select_using_dropdown(dropdown_type, selection, is_commit = false)
    dropdown = find(".js-compare-#{dropdown_type}-dropdown")
    dropdown.find(".compare-dropdown-toggle").click
    dropdown.find('.dropdown-menu', visible: true)
    dropdown.fill_in("Filter by Git revision", with: selection)

    if is_commit
      dropdown.find('input[type="search"]').send_keys(:return)
    else
      find_link(selection, visible: true).click
    end

    dropdown.find('.dropdown-menu', visible: false)
  end
end
