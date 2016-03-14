@project_merge_requests
Feature: Project Merge Requests
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" have "Bug NS-04" open merge request
    And project "Shop" have "Feature NS-03" closed merge request
    And I visit project "Shop" merge requests page

  Scenario: I should see open merge requests
    Then I should see "Bug NS-04" in merge requests
    And I should not see "Feature NS-03" in merge requests

  Scenario: I should see CI status for merge requests
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    Given "Bug NS-05" has CI status
    When I visit project "Shop" merge requests page
    Then I should see merge request "Bug NS-05" with CI status

  Scenario: I should not see target branch name when it is project's default branch
    Then I should see "Bug NS-04" in merge requests
    And I should not see "master" branch

  Scenario: I should see target branch when it is different from default
    Given project "Shop" have "Bug NS-06" open merge request
    When I visit project "Shop" merge requests page
    Then I should see "other_branch" branch

  Scenario: I should not see the numbers of diverged commits if the branch is rebased on the target
    Given project "Shop" have "Bug NS-07" open merge request with rebased branch
    When I visit merge request page "Bug NS-07"
    Then I should not see the diverged commits count

  Scenario: I should see the numbers of diverged commits if the branch diverged from the target
    Given project "Shop" have "Bug NS-08" open merge request with diverged branch
    When I visit merge request page "Bug NS-08"
    Then I should see the diverged commits count

  Scenario: I should see rejected merge requests
    Given I click link "Closed"
    Then I should see "Feature NS-03" in merge requests
    And I should not see "Bug NS-04" in merge requests

  Scenario: I should see all merge requests
    Given I click link "All"
    Then I should see "Feature NS-03" in merge requests
    And I should see "Bug NS-04" in merge requests

  Scenario: I visit merge request page
    Given I click link "Bug NS-04"
    Then I should see merge request "Bug NS-04"
    And I should see "1 of 1" in the sidebar

  Scenario: I close merge request page
    Given I click link "Bug NS-04"
    And I click link "Close"
    Then I should see closed merge request "Bug NS-04"

  Scenario: I reopen merge request page
    Given I click link "Bug NS-04"
    And I click link "Close"
    Then I should see closed merge request "Bug NS-04"
    When I click link "Reopen"
    Then I should see reopened merge request "Bug NS-04"

  Scenario: I submit new unassigned merge request
    Given I click link "New Merge Request"
    And I submit new merge request "Wiki Feature"
    Then I should see merge request "Wiki Feature"

  Scenario: I download a diff on a public merge request
    Given public project "Community"
    And "John Doe" owns public project "Community"
    And project "Community" has "Bug CO-01" open merge request with diffs inside
    Given I logout directly
    And I visit merge request page "Bug CO-01"
    And I click on "Email Patches"
    Then I should see a patch diff
    And I visit merge request page "Bug CO-01"
    And I click on "Plain Diff"
    Then I should see a patch diff

  @javascript
  Scenario: I comment on a merge request
    Given I visit merge request page "Bug NS-04"
    And I leave a comment like "XML attached"
    Then I should see comment "XML attached"

  @javascript
  Scenario: Visiting Merge Requests after being sorted the list
    Given I visit project "Shop" merge requests page
    And I sort the list by "Oldest updated"
    And I visit my project's home page
    And I visit project "Shop" merge requests page
    Then The list should be sorted by "Oldest updated"

  @javascript
  Scenario: Visiting Issues after being sorted the list
    Given I visit project "Shop" merge requests page
    And I sort the list by "Oldest updated"
    And I visit project "Shop" issues page
    Then The list should be sorted by "Oldest updated"

  @javascript
  Scenario: Visiting Merge Requests from a differente Project after sorting
    Given I visit project "Shop" merge requests page
    And I sort the list by "Oldest updated"
    And I visit dashboard merge requests page
    Then The list should be sorted by "Oldest updated"

  @javascript
  Scenario: Sort merge requests by upvotes/downvotes
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And project "Shop" have "Bug NS-06" open merge request
    And merge request "Bug NS-04" have 2 upvotes and 1 downvote
    And merge request "Bug NS-06" have 1 upvote and 2 downvotes
    And I sort the list by "Most popular"
    Then The list should be sorted by "Most popular"
    And I sort the list by "Least popular"
    Then The list should be sorted by "Least popular"

  @javascript
  Scenario: I comment on a merge request diff
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the Changes tab
    And I leave a comment like "Line is wrong" on diff
    And I switch to the merge request's comments tab
    Then I should see a discussion has started on diff
    And I should see a badge of "1" next to the discussion link

  @javascript
  Scenario: I see a new comment on merge request diff from another user in the discussion tab
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And user "John Doe" leaves a comment like "Line is wrong" on diff
    Then I should see a discussion by user "John Doe" has started on diff
    And I should see a badge of "1" next to the discussion link

  @javascript
  Scenario: I edit a comment on a merge request diff
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the Changes tab
    And I leave a comment like "Line is wrong" on diff
    And I change the comment "Line is wrong" to "Typo, please fix" on diff
    Then I should not see a diff comment saying "Line is wrong"
    And I should see a diff comment saying "Typo, please fix"

  @javascript
  Scenario: I delete a comment on a merge request diff
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the Changes tab
    And I leave a comment like "Line is wrong" on diff
    And I should see a badge of "1" next to the discussion link
    And I delete the comment "Line is wrong" on diff
    And I click on the Discussion tab
    Then I should not see any discussion
    And I should see a badge of "0" next to the discussion link

  @javascript
  Scenario: I comment on a line of a commit in merge request
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the commit in the merge request
    And I leave a comment like "Line is wrong" on diff in commit
    And I switch to the merge request's comments tab
    Then I should see a discussion has started on commit diff

  @javascript
  Scenario: I comment on a commit in merge request
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the commit in the merge request
    And I leave a comment on the diff page in commit
    And I switch to the merge request's comments tab
    Then I should see a discussion has started on commit

  @javascript
  Scenario: I accept merge request with custom commit message
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And merge request "Bug NS-05" is mergeable
    And I visit merge request page "Bug NS-05"
    And merge request is mergeable
    Then I modify merge commit message
    And I accept this merge request
    Then I should see merged request

  # Markdown

  Scenario: Headers inside the description should have ids generated for them.
    When I visit merge request page "Bug NS-04"
    Then Header "Description header" should have correct id and link

  @javascript
  Scenario: Headers inside comments should not have ids generated for them.
    Given I visit merge request page "Bug NS-04"
    And I leave a comment with a header containing "Comment with a header"
    Then The comment with the header should not have an ID

  # Toggling inline comments

  @javascript
  Scenario: I hide comments on a merge request diff with comments in a single file
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the Changes tab
    And I leave a comment like "Line is wrong" on line 39 of the third file
    And I click link "Hide inline discussion" of the third file
    Then I should not see a comment like "Line is wrong here" in the third file

  @javascript
  Scenario: I show comments on a merge request diff with comments in a single file
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the Changes tab
    And I leave a comment like "Line is wrong" on line 39 of the third file
    Then I should see a comment like "Line is wrong" in the third file

  @javascript
  Scenario: I hide comments on a merge request diff with comments in multiple files
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the Changes tab
    And I leave a comment like "Line is correct" on line 12 of the second file
    And I leave a comment like "Line is wrong" on line 39 of the third file
    And I click link "Hide inline discussion" of the third file
    Then I should not see a comment like "Line is wrong here" in the third file
    And I should still see a comment like "Line is correct" in the second file

  @javascript
  Scenario: I show comments on a merge request diff with comments in multiple files
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the Changes tab
    And I leave a comment like "Line is correct" on line 12 of the second file
    And I leave a comment like "Line is wrong" on line 39 of the third file
    And I click link "Hide inline discussion" of the third file
    And I click link "Show inline discussion" of the third file
    Then I should see a comment like "Line is wrong" in the third file
    And I should still see a comment like "Line is correct" in the second file

  @javascript
  Scenario: I unfold diff
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the Changes tab
    And I unfold diff
    Then I should see additional file lines

  @javascript
  Scenario: I show comments on a merge request side-by-side diff with comments in multiple files
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the Changes tab
    And I leave a comment like "Line is correct" on line 12 of the second file
    And I leave a comment like "Line is wrong" on line 39 of the third file
    And I click Side-by-side Diff tab
    Then I should see comments on the side-by-side diff page

  @javascript
  Scenario: I view diffs on a merge request
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the Changes tab
    Then I should see the proper Inline and Side-by-side links

  # Description preview

  @javascript
  Scenario: I can't preview without text
    Given I visit merge request page "Bug NS-04"
    And I click link "Edit" for the merge request
    And I haven't written any description text
    Then The Markdown preview tab should say there is nothing to do

  @javascript
  Scenario: I can preview with text
    Given I visit merge request page "Bug NS-04"
    And I click link "Edit" for the merge request
    And I write a description like ":+1: Nice"
    Then The Markdown preview tab should display rendered Markdown

  @javascript
  Scenario: I preview a merge request description
    Given I visit merge request page "Bug NS-04"
    And I click link "Edit" for the merge request
    And I preview a description text like "Bug fixed :smile:"
    Then I should see the Markdown preview
    And I should not see the Markdown text field

  @javascript
  Scenario: I can edit after preview
    Given I visit merge request page "Bug NS-04"
    And I click link "Edit" for the merge request
    And I preview a description text like "Bug fixed :smile:"
    Then I should see the Markdown write tab

  @javascript
  Scenario: I search merge request
    Given I click link "All"
    When I fill in merge request search with "Fe"
    Then I should see "Feature NS-03" in merge requests
    And I should not see "Bug NS-04" in merge requests

  @javascript
  Scenario: I can unsubscribe from merge request
    Given I visit merge request page "Bug NS-04"
    Then I should see that I am subscribed
    When I click button "Unsubscribe"
    Then I should see that I am unsubscribed

  @javascript
  Scenario: I can change the target branch
    Given I visit merge request page "Bug NS-04"
    And I click link "Edit" for the merge request
    When I click the "Target branch" dropdown
    And I select a new target branch
    Then I should see new target branch changes
