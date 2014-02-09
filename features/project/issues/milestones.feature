Feature: Project Milestones
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has milestone "v2.2"
    Given I visit project "Shop" milestones page

  Scenario: I should see active milestones
    Then I should see milestone "v2.2"

  Scenario: I should see milestone
    Given I click link "v2.2"
    Then I should see milestone "v2.2"

  Scenario: I create new milestone
    Given I click link "New Milestone"
    And I submit new milestone "v2.3"
    Then I should see milestone "v2.3"

  @javascript
  Scenario: Listing closed issues
    Given the milestone has open and closed issues
    And I click link "v2.2"
    Then I should see 3 issues

  # Markdown

  Scenario: Headers inside the description should have ids generated for them.
    Given I click link "v2.2"
    Then Header "Description header" should have correct id and link

  # Preview

  @javascript
  Scenario: I preview milestone description while creating it
    Given I click link "New Milestone"
    And I input a description with a header
    And I click on the description preview button
    Then The description preview header should have an id

  @javascript
  Scenario: I preview milestone description while editing it
    Given I click link "v2.2"
    And I click link "Edit"
    And I input a description with a header
    And I click on the description preview button
    Then The description preview header should have an id
