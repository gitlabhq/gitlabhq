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

  Scenario: I submit new unassigned issue
    Given I click link "New Issue"
    And I submit new issue "500 error on profile"
    Then I should see issue "500 error on profile"

  @javascript
  Scenario: I comment issue
    Given I visit issue page "Release 0.4"
    And I leave a comment like "XML attached"
    Then I should see comment "XML attached"

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

  Scenario: Issues on empty project
    Given empty project "Empty Project"
    When I visit empty project page
    And I see empty project details with ssh clone info
    When I visit empty project's issues page
    Given I click link "New Issue"
    And I submit new issue "500 error on profile"
    Then I should see issue "500 error on profile"

  # Markdown

  Scenario: Headers inside the description should have ids generated for them.
    Given I visit issue page "Release 0.4"
    Then Header "Description header" should have correct id and link

  @javascript
  Scenario: Headers inside comments should not have ids generated for them.
    Given I visit issue page "Release 0.4"
    And I leave a comment with a header containing "Comment with a header"
    Then The comment with the header should not have an ID

  # Preview

  @javascript
  Scenario: I can't preview description without text
    Given I click link "New Issue"
    Then The description preview button should be disabled

  @javascript
  Scenario: I can preview non empty description before I start editing
    Given I click link "Release 0.4"
    And I click link "Edit"
    Then The description preview button should be enabled

  @javascript
  Scenario: I preview issue description while creating it
    Given I click link "New Issue"
    And I input a description with a header
    And I click on the description preview button
    Then The description preview header should have an id

  @javascript
  Scenario: I preview issue description while editing it
    Given I click link "Release 0.4"
    And I click link "Edit"
    And I input a description with a header
    And I click on the description preview button
    Then The description preview header should have an id
