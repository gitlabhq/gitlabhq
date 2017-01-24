class Spinach::Features::ProjectMergeRequests < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedIssuable
  include SharedProject
  include SharedNote
  include SharedPaths
  include SharedMarkdown
  include SharedDiffNote
  include SharedUser
  include WaitForAjax

  after do
    wait_for_ajax if javascript_test?
  end

  step 'I click link "New Merge Request"' do
    click_link "New Merge Request"
  end

  step 'I click link "Bug NS-04"' do
    click_link "Bug NS-04"
  end

  step 'I click link "Feature NS-05"' do
    click_link "Feature NS-05"
  end

  step 'I click link "All"' do
    click_link "All"
    # Waits for load
    expect(find('.issues-state-filters > .active')).to have_content 'All'
  end

  step 'I click link "Merged"' do
    click_link "Merged"
  end

  step 'I click link "Closed"' do
    page.within('.issues-state-filters') do
      click_link "Closed"
    end
  end

  step 'I should see merge request "Wiki Feature"' do
    page.within '.merge-request' do
      expect(page).to have_content "Wiki Feature"
    end
  end

  step 'I should see closed merge request "Bug NS-04"' do
    merge_request = MergeRequest.find_by!(title: "Bug NS-04")
    expect(merge_request).to be_closed
    expect(page).to have_content "Closed by"
  end

  step 'I should see merge request "Bug NS-04"' do
    expect(page).to have_content "Bug NS-04"
  end

  step 'I should see merge request "Feature NS-05"' do
    expect(page).to have_content "Feature NS-05"
  end

  step 'I should not see "master" branch' do
    expect(find('.merge-request-info')).not_to have_content "master"
  end

  step 'I should see "feature_conflict" branch' do
    expect(page).to have_content "feature_conflict"
  end

  step 'I should see "Bug NS-04" in merge requests' do
    expect(page).to have_content "Bug NS-04"
  end

  step 'I should see "Feature NS-03" in merge requests' do
    expect(page).to have_content "Feature NS-03"
  end

  step 'I should not see "Feature NS-03" in merge requests' do
    expect(page).not_to have_content "Feature NS-03"
  end

  step 'I should not see "Bug NS-04" in merge requests' do
    expect(page).not_to have_content "Bug NS-04"
  end

  step 'I should see that I am subscribed' do
    expect(find('.issuable-subscribe-button span')).to have_content 'Unsubscribe'
  end

  step 'I should see that I am unsubscribed' do
    expect(find('.issuable-subscribe-button span')).to have_content 'Subscribe'
  end

  step 'I click button "Unsubscribe"' do
    click_on "Unsubscribe"
    wait_for_ajax
  end

  step 'I click link "Close"' do
    first(:css, '.close-mr-link').click
  end

  step 'I submit new merge request "Wiki Feature"' do
    find('.js-source-branch').click
    find('.dropdown-source-branch .dropdown-content a', text: 'fix').click

    find('.js-target-branch').click
    first('.dropdown-target-branch .dropdown-content a', text: 'feature').click

    click_button "Compare branches"
    fill_in "merge_request_title", with: "Wiki Feature"
    click_button "Submit merge request"
  end

  step 'project "Shop" have "Bug NS-04" open merge request' do
    create(:merge_request,
           title: "Bug NS-04",
           source_project: project,
           target_project: project,
           source_branch: 'fix',
           target_branch: 'merge-test',
           author: project.users.first,
           description: "# Description header"
          )
  end

  step 'project "Shop" have "Bug NS-06" open merge request' do
    create(:merge_request,
           title: "Bug NS-06",
           source_project: project,
           target_project: project,
           source_branch: 'fix',
           target_branch: 'feature_conflict',
           author: project.users.first,
           description: "# Description header"
          )
  end

  step 'project "Shop" have "Bug NS-05" open merge request with diffs inside' do
    create(:merge_request_with_diffs,
           title: "Bug NS-05",
           source_project: project,
           target_project: project,
           author: project.users.first,
           source_branch: 'merge-test')
  end

  step 'project "Shop" have "Feature NS-05" merged merge request' do
    create(:merged_merge_request,
           title: "Feature NS-05",
           source_project: project,
           target_project: project,
           author: project.users.first)
  end

  step 'project "Shop" have "Bug NS-07" open merge request with rebased branch' do
    create(:merge_request, :rebased,
      title: "Bug NS-07",
      source_project: project,
      target_project: project,
      author: project.users.first)
  end

  step 'project "Shop" have "Bug NS-08" open merge request with diverged branch' do
    create(:merge_request, :diverged,
      title: "Bug NS-08",
      source_project: project,
      target_project: project,
      author: project.users.first)
  end

  step 'project "Shop" have "Feature NS-03" closed merge request' do
    create(:closed_merge_request,
           title: "Feature NS-03",
           source_project: project,
           target_project: project,
           author: project.users.first)
  end

  step 'project "Community" has "Bug CO-01" open merge request with diffs inside' do
    project = Project.find_by(name: "Community")
    create(:merge_request_with_diffs,
           title: "Bug CO-01",
           source_project: project,
           target_project: project,
           author: project.users.first)
  end

  step 'merge request "Bug NS-04" have 2 upvotes and 1 downvote' do
    merge_request = MergeRequest.find_by(title: 'Bug NS-04')
    create_list(:award_emoji, 2, awardable: merge_request)
    create(:award_emoji, :downvote, awardable: merge_request)
  end

  step 'merge request "Bug NS-06" have 1 upvote and 2 downvotes' do
    awardable = MergeRequest.find_by(title: 'Bug NS-06')
    create(:award_emoji, awardable: awardable)
    create_list(:award_emoji, 2, :downvote, awardable: awardable)
  end

  step 'The list should be sorted by "Least popular"' do
    page.within '.mr-list' do
      page.within 'li.merge-request:nth-child(1)' do
        expect(page).to have_content 'Bug NS-06'
        expect(page).to have_content '1 2'
      end

      page.within 'li.merge-request:nth-child(2)' do
        expect(page).to have_content 'Bug NS-04'
        expect(page).to have_content '2 1'
      end

      page.within 'li.merge-request:nth-child(3)' do
        expect(page).to have_content 'Bug NS-05'
        expect(page).not_to have_content '0 0'
      end
    end
  end

  step 'The list should be sorted by "Most popular"' do
    page.within '.mr-list' do
      page.within 'li.merge-request:nth-child(1)' do
        expect(page).to have_content 'Bug NS-04'
        expect(page).to have_content '2 1'
      end

      page.within 'li.merge-request:nth-child(2)' do
        expect(page).to have_content 'Bug NS-06'
        expect(page).to have_content '1 2'
      end

      page.within 'li.merge-request:nth-child(3)' do
        expect(page).to have_content 'Bug NS-05'
        expect(page).not_to have_content '0 0'
      end
    end
  end

  step 'I click on the Changes tab' do
    page.within '.merge-request-tabs' do
      click_link 'Changes'
    end

    # Waits for load
    expect(page).to have_css('.tab-content #diffs.active')
  end

  step 'I should see the proper Inline and Side-by-side links' do
    expect(page).to have_css('#parallel-diff-btn', count: 1)
    expect(page).to have_css('#inline-diff-btn', count: 1)
  end

  step 'I switch to the merge request\'s comments tab' do
    visit namespace_project_merge_request_path(project.namespace, project, merge_request)
  end

  step 'I click on the commit in the merge request' do
    page.within '.merge-request-tabs' do
      click_link 'Commits'
    end

    page.within '.commits' do
      click_link Commit.truncate_sha(sample_commit.id)
    end
  end

  step 'I leave a comment on the diff page' do
    init_diff_note
    leave_comment "One comment to rule them all"
  end

  step 'I leave a comment on the diff page in commit' do
    click_diff_line(sample_commit.line_code)
    leave_comment "One comment to rule them all"
  end

  step 'I leave a comment like "Line is wrong" on diff' do
    init_diff_note
    leave_comment "Line is wrong"
  end

  step 'user "John Doe" leaves a comment like "Line is wrong" on diff' do
    mr = MergeRequest.find_by(title: "Bug NS-05")
    create(:diff_note_on_merge_request, project: project,
                                        noteable: mr,
                                        author: user_exists("John Doe"),
                                        note: 'Line is wrong')
  end

  step 'I leave a comment like "Line is wrong" on diff in commit' do
    click_diff_line(sample_commit.line_code)
    leave_comment "Line is wrong"
  end

  step 'I change the comment "Line is wrong" to "Typo, please fix" on diff' do
    page.within('.diff-file:nth-of-type(5) .note') do
      find('.js-note-edit').click

      page.within('.current-note-edit-form', visible: true) do
        fill_in 'note_note', with: 'Typo, please fix'
        click_button 'Save Comment'
      end

      expect(page).not_to have_button 'Save Comment', disabled: true, visible: true
    end
  end

  step 'I should not see a diff comment saying "Line is wrong"' do
    page.within('.diff-file:nth-of-type(5) .note') do
      expect(page).not_to have_visible_content 'Line is wrong'
    end
  end

  step 'I should see a diff comment saying "Typo, please fix"' do
    page.within('.diff-file:nth-of-type(5) .note') do
      expect(page).to have_visible_content 'Typo, please fix'
    end
  end

  step 'I delete the comment "Line is wrong" on diff' do
    page.within('.diff-file:nth-of-type(5) .note') do
      find('.js-note-delete').click
    end
  end

  step 'I click on the Discussion tab' do
    page.within '.merge-request-tabs' do
      click_link 'Discussion'
    end

    # Waits for load
    expect(page).to have_css('.tab-content #notes.active')
  end

  step 'I should not see any discussion' do
    expect(page).not_to have_css('.notes .discussion')
  end

  step 'I should see a discussion has started on diff' do
    page.within(".notes .discussion") do
      page.should have_content "#{current_user.name} #{current_user.to_reference} started a discussion"
      page.should have_content sample_commit.line_code_path
      page.should have_content "Line is wrong"
    end
  end

  step 'I should see a discussion by user "John Doe" has started on diff' do
    page.within(".notes .discussion") do
      page.should have_content "#{user_exists("John Doe").name} #{user_exists("John Doe").to_reference} started a discussion"
      page.should have_content sample_commit.line_code_path
      page.should have_content "Line is wrong"
    end
  end

  step 'I should see a badge of "1" next to the discussion link' do
    expect_discussion_badge_to_have_counter("1")
  end

  step 'I should see a badge of "0" next to the discussion link' do
    expect_discussion_badge_to_have_counter("0")
  end

  step 'I should see a discussion has started on commit diff' do
    page.within(".notes .discussion") do
      page.should have_content "#{current_user.name} #{current_user.to_reference} started a discussion on commit"
      page.should have_content sample_commit.line_code_path
      page.should have_content "Line is wrong"
    end
  end

  step 'I should see a discussion has started on commit' do
    page.within(".notes .discussion") do
      page.should have_content "#{current_user.name} #{current_user.to_reference} started a discussion on commit"
      page.should have_content "One comment to rule them all"
    end
  end

  step 'merge request is mergeable' do
    expect(page).to have_button 'Accept Merge Request'
  end

  step 'I modify merge commit message' do
    find('.modify-merge-commit-link').click
    fill_in 'commit_message', with: 'wow such merge'
  end

  step 'merge request "Bug NS-05" is mergeable' do
    merge_request.mark_as_mergeable
  end

  step 'I accept this merge request' do
    page.within '.mr-state-widget' do
      click_button "Accept Merge Request"
    end
  end

  step 'I should see merged request' do
    page.within '.status-box' do
      expect(page).to have_content "Merged"
    end
  end

  step 'I click link "Reopen"' do
    first(:css, '.reopen-mr-link').click
  end

  step 'I should see reopened merge request "Bug NS-04"' do
    page.within '.status-box' do
      expect(page).to have_content "Open"
    end
  end

  step 'I click link "Hide inline discussion" of the third file' do
    page.within '.files>div:nth-child(3)' do
      find('.js-toggle-diff-comments').trigger('click')
    end
  end

  step 'I click link "Show inline discussion" of the third file' do
    page.within '.files>div:nth-child(3)' do
      find('.js-toggle-diff-comments').trigger('click')
    end
  end

  step 'I should not see a comment like "Line is wrong" in the third file' do
    page.within '.files>div:nth-child(3)' do
      expect(page).not_to have_visible_content "Line is wrong"
    end
  end

  step 'I should see a comment like "Line is wrong" in the third file' do
    page.within '.files>div:nth-child(3) .note-body > .note-text' do
      expect(page).to have_visible_content "Line is wrong"
    end
  end

  step 'I should not see a comment like "Line is wrong here" in the third file' do
    page.within '.files>div:nth-child(3)' do
      expect(page).not_to have_visible_content "Line is wrong here"
    end
  end

  step 'I should see a comment like "Line is wrong here" in the third file' do
    page.within '.files>div:nth-child(3) .note-body > .note-text' do
      expect(page).to have_visible_content "Line is wrong here"
    end
  end

  step 'I leave a comment like "Line is correct" on line 12 of the second file' do
    init_diff_note_first_file

    page.within(".js-discussion-note-form") do
      fill_in "note_note", with: "Line is correct"
      click_button "Comment"
    end

    page.within ".files>div:nth-child(2) .note-body > .note-text" do
      expect(page).to have_content "Line is correct"
    end
  end

  step 'I leave a comment like "Line is wrong" on line 39 of the third file' do
    init_diff_note_second_file

    page.within(".js-discussion-note-form") do
      fill_in "note_note", with: "Line is wrong on here"
      click_button "Comment"
    end
  end

  step 'I should still see a comment like "Line is correct" in the second file' do
    page.within '.files>div:nth-child(2) .note-body > .note-text' do
      expect(page).to have_visible_content "Line is correct"
    end
  end

  step 'I unfold diff' do
    expect(page).to have_css('.js-unfold')

    first('.js-unfold').click
  end

  step 'I should see additional file lines' do
    expect(first('.text-file')).to have_content('.bundle')
  end

  step 'I click Side-by-side Diff tab' do
    find('a', text: 'Side-by-side').trigger('click')

    # Waits for load
    expect(page).to have_css('.parallel')
  end

  step 'I should see comments on the side-by-side diff page' do
    page.within '.files>div:nth-child(2) .parallel .note-body > .note-text' do
      expect(page).to have_visible_content "Line is correct"
    end
  end

  step 'I fill in merge request search with "Fe"' do
    fill_in 'issuable_search', with: "Fe"
  end

  step 'I click the "Target branch" dropdown' do
    expect(page).to have_content('Target branch')
    first('.target_branch').click
  end

  step 'I select a new target branch' do
    select "feature", from: "merge_request_target_branch"
    click_button 'Save'
  end

  step 'I should see new target branch changes' do
    expect(page).to have_content 'Request to merge fix into feature'
    expect(page).to have_content 'changed target branch from merge-test to feature'
    wait_for_ajax
  end

  step 'I click on "Email Patches"' do
    click_link "Email Patches"
  end

  step 'I click on "Plain Diff"' do
    click_link "Plain Diff"
  end

  step 'I should see a patch diff' do
    expect(page).to have_content('diff --git')
  end

  step '"Bug NS-05" has CI status' do
    project = merge_request.source_project
    project.enable_ci
    pipeline = create :ci_pipeline, project: project, sha: merge_request.diff_head_sha, ref: merge_request.source_branch
    create :ci_build, pipeline: pipeline
  end

  step 'I should see merge request "Bug NS-05" with CI status' do
    page.within ".mr-list" do
      expect(page).to have_link "Pipeline: pending"
    end
  end

  step 'I should see the diverged commits count' do
    page.within ".mr-source-target" do
      expect(page).to have_content /([0-9]+ commits behind)/
    end
  end

  step 'I should not see the diverged commits count' do
    page.within ".mr-source-target" do
      expect(page).not_to have_content /([0-9]+ commit[s]? behind)/
    end
  end

  def merge_request
    @merge_request ||= MergeRequest.find_by!(title: "Bug NS-05")
  end

  def init_diff_note
    click_diff_line(sample_commit.line_code)
  end

  def leave_comment(message)
    page.within(".js-discussion-note-form", visible: true) do
      fill_in "note_note", with: message
      click_button "Comment"
    end
    page.within(".notes_holder", visible: true) do
      expect(page).to have_content message
    end
  end

  def init_diff_note_first_file
    click_diff_line(sample_compare.changes[0][:line_code])
  end

  def init_diff_note_second_file
    click_diff_line(sample_compare.changes[1][:line_code])
  end

  def have_visible_content(text)
    have_css("*", text: text, visible: true)
  end

  def expect_discussion_badge_to_have_counter(value)
    page.within(".notes-tab .badge") do
      page.should have_content value
    end
  end
end
