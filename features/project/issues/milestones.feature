@project_issues
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

  @javascript
  Scenario: I create and delete new milestone
    Given I click link "New Milestone"
    And I submit new milestone "v2.3"
    Then I should see milestone "v2.3"
    Given I click button to remove milestone
    And I confirm in modal
    When I visit project "Shop" activity page
    Then I should see deleted milestone activity

  @javascript
  Scenario: I delete new milestone
    Given I click button to remove milestone
    And I confirm in modal
    And I should see no milestones

  @javascript
  Scenario: Listing closed issues
    Given the milestone has open and closed issues
    And I click link "v2.2"
    Then I should see 3 issues

  # Markdown

  Scenario: Headers inside the description should have ids generated for them.
    Given I click link "v2.2"
    # PLEASE USE the `have_header_with_correct_id_and_link(level, text, id, parent)` matcher on migrating this spec to rspec.
    Then Header "Description header" should have correct id and link
