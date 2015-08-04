Feature: Project Issues Milestones
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

  Scenario: I delete new milestone
    Given I click link to remove milestone "v2.2"
    And I should see no milestones

  @javascript
  Scenario: Listing closed issues
    Given the milestone has open and closed issues
    And I click link "v2.2"
    Then I should see 3 issues

  # Markdown

  Scenario: Headers inside the description should have ids generated for them.
    Given I click link "v2.2"
    Then Header "Description header" should have correct id and link
