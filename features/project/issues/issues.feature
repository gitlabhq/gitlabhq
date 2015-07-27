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

  Scenario: I should see closed issues
    Given I click link "Closed"
    Then I should see "Release 0.3" in issues
    And I should not see "Release 0.4" in issues

  Scenario: I should see all issues
    Given I click link "All"
    Then I should see "Release 0.3" in issues
    And I should see "Release 0.4" in issues

  Scenario: I visit issue page
    Given I click link "Release 0.4"
    Then I should see issue "Release 0.4"

  @javascript
  Scenario: I visit issue page
    Given I add a user to project "Shop"
    And I click "author" dropdown
    Then I see current user as the first user

  Scenario: I submit new unassigned issue
    Given I click link "New Issue"
    And I submit new issue "500 error on profile"
    Then I should see issue "500 error on profile"

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
  Scenario: I search issue
    Given I fill in issue search with "Re"
    Then I should see "Release 0.4" in issues
    And I should not see "Release 0.3" in issues
    And I should not see "Tweet control" in issues

  @javascript
  Scenario: I search issue that not exist
    Given I fill in issue search with "Bu"
    Then I should not see "Release 0.4" in issues
    And I should not see "Release 0.3" in issues

  @javascript
  Scenario: I search all issues
    Given I click link "All"
    And I fill in issue search with ".3"
    Then I should see "Release 0.3" in issues
    And I should not see "Release 0.4" in issues

  @javascript
  Scenario: Search issues when search string exactly matches issue description
    Given project 'Shop' has issue 'Bugfix1' with description: 'Description for issue1'
    And I fill in issue search with 'Description for issue1'
    Then I should see 'Bugfix1' in issues
    And I should not see "Release 0.4" in issues
    And I should not see "Release 0.3" in issues
    And I should not see "Tweet control" in issues

  @javascript
  Scenario: Search issues when search string partially matches issue description
    Given project 'Shop' has issue 'Bugfix1' with description: 'Description for issue1'
    And project 'Shop' has issue 'Feature1' with description: 'Feature submitted for issue1'
    And I fill in issue search with 'issue1'
    Then I should see 'Feature1' in issues
    Then I should see 'Bugfix1' in issues
    And I should not see "Release 0.4" in issues
    And I should not see "Release 0.3" in issues
    And I should not see "Tweet control" in issues

  @javascript
  Scenario: Search issues when search string matches no issue description
    Given project 'Shop' has issue 'Bugfix1' with description: 'Description for issue1'
    And I fill in issue search with 'Rock and roll'
    Then I should not see 'Bugfix1' in issues
    And I should not see "Release 0.4" in issues
    And I should not see "Release 0.3" in issues
    And I should not see "Tweet control" in issues


  # Markdown

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
    When I click button "Unsubscribe"
    Then I should see that I am unsubscribed

  Scenario: I submit new unassigned issue as guest
    Given I logout
    Given public project "Community"
    When I visit project "Community" page
    And I visit project "Community" issues page
    And I click link "New Issue"
    And I should not see assignee field
    And I should not see milestone field
    And I should not see labels field
    And I submit new issue "500 error on profile"
    Then I should see issue "500 error on profile"

