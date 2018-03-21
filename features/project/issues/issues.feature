@project_issues
Feature: Project Issues
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" have "Release 0.4" open issue
    And project "Shop" have "Tweet control" open issue
    And project "Shop" have "Release 0.3" closed issue
    And I visit project "Shop" issues page

  Scenario: I should see open issues
    Given I should see "Release 0.4" in issues
    And I should not see "Release 0.3" in issues

  @javascript
  Scenario: I should see closed issues
    Given I click link "Closed"
    Then I should see "Release 0.3" in issues
    And I should not see "Release 0.4" in issues

  @javascript
  Scenario: I should see all issues
    Given I click link "All"
    Then I should see "Release 0.3" in issues
    And I should see "Release 0.4" in issues

  Scenario: I visit issue page
    Given I click link "Release 0.4"
    Then I should see issue "Release 0.4"

  Scenario: I submit new unassigned issue
    Given I click link "New Issue"
    And I submit new issue "500 error on profile"
    Then I should see issue "500 error on profile"

  @javascript
  Scenario: I submit new unassigned issue with labels
    Given project "Shop" has labels: "bug", "feature", "enhancement"
    And I click link "New Issue"
    And I submit new issue "500 error on profile" with label 'bug'
    Then I should see issue "500 error on profile"
    And I should see label 'bug' with issue

  @javascript
  Scenario: I comment issue
    Given I visit issue page "Release 0.4"
    And I leave a comment like "XML attached"
    Then I should see comment "XML attached"
    And I should see an error alert section within the comment form

  @javascript
  Scenario: Visiting Issues after being sorted the list
    Given I visit project "Shop" issues page
    And I sort the list by "Last updated"
    And I visit my project's home page
    And I visit project "Shop" issues page
    Then The list should be sorted by "Last updated"

  @javascript
  Scenario: Visiting Merge Requests after being sorted the list
    Given project "Shop" has a "Bugfix MR" merge request open
    And I visit project "Shop" issues page
    And I sort the list by "Last updated"
    And I visit project "Shop" merge requests page
    Then The list should be sorted by "Last updated"

  @javascript
  Scenario: Visiting Merge Requests from a differente Project after sorting
    Given project "Shop" has a "Bugfix MR" merge request open
    And I visit project "Shop" merge requests page
    And I sort the list by "Last updated"
    And I visit dashboard merge requests page
    Then The list should be sorted by "Last updated"

  @javascript
  Scenario: Sort issues by upvotes/downvotes
    Given project "Shop" have "Bugfix" open issue
    And issue "Release 0.4" have 2 upvotes and 1 downvote
    And issue "Tweet control" have 1 upvote and 2 downvotes
    And I sort the list by "Popularity"
    Then The list should be sorted by "Popularity"

  # Markdown

  @javascript
  Scenario: Headers inside the description should have ids generated for them.
    Given I visit issue page "Release 0.4"
    Then Header "Description header" should have correct id and link

  @javascript
  Scenario: Headers inside comments should not have ids generated for them.
    Given I visit issue page "Release 0.4"
    And I leave a comment with a header containing "Comment with a header"
    Then The comment with the header should not have an ID

  @javascript
  Scenario: Blocks inside comments should not build relative links
    Given I visit issue page "Release 0.4"
    And I leave a comment with code block
    Then The code block should be unchanged

  Scenario: Issues on empty project
    Given empty project "Empty Project"
    And I have an ssh key
    When I visit empty project page
    And I see empty project details with ssh clone info
    When I visit empty project's issues page
    Given I click link "New Issue"
    And I submit new issue "500 error on profile"
    Then I should see issue "500 error on profile"

  Scenario: Clickable labels
    Given issue 'Release 0.4' has label 'bug'
    And I visit project "Shop" issues page
    When I click label 'bug'
    And I should see "Release 0.4" in issues
    And I should not see "Tweet control" in issues

  @javascript
  Scenario: Issue notes should be editable with +1
    Given project "Shop" have "Release 0.4" open issue
    When I visit issue page "Release 0.4"
    And I leave a comment with a header containing "Comment with a header"
    Then The comment with the header should not have an ID
    And I edit the last comment with a +1
    Then I should see +1 in the description

  # Issue description preview

  @javascript
  Scenario: I can't preview without text
    Given I click link "New Issue"
    And I haven't written any description text
    Then The Markdown preview tab should say there is nothing to do

  @javascript
  Scenario: I can preview with text
    Given I click link "New Issue"
    And I write a description like ":+1: Nice"
    Then The Markdown preview tab should display rendered Markdown

  @javascript
  Scenario: I preview an issue description
    Given I click link "New Issue"
    And I preview a description text like "Bug fixed :smile:"
    Then I should see the Markdown preview
    And I should not see the Markdown text field

  @javascript
  Scenario: I can edit after preview
    Given I click link "New Issue"
    And I preview a description text like "Bug fixed :smile:"
    Then I should see the Markdown write tab

  @javascript
  Scenario: I can preview when editing an existing issue
    Given I click link "Release 0.4"
    And I click link "Edit" for the issue
    And I preview a description text like "Bug fixed :smile:"
    Then I should see the Markdown write tab

  @javascript
  Scenario: I can unsubscribe from issue
    Given project "Shop" have "Release 0.4" open issue
    When I visit issue page "Release 0.4"
    Then I should see that I am subscribed
    When I click the subscription toggle
    Then I should see that I am unsubscribed

  @javascript
  Scenario: I submit new unassigned issue as guest
    Given public project "Community"
    When I visit project "Community" page
    And I visit project "Community" issues page
    And I click link "New Issue"
    And I should not see assignee field
    And I should not see milestone field
    And I should not see labels field
    And I submit new issue "500 error on profile"
    Then I should see issue "500 error on profile"
