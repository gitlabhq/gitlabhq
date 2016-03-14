Feature: Project Group Links
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" is shared with group "Ops"
    And project "Shop" is not shared with group "Market"
    And I visit project group links page

  Scenario: I should see list of groups
    Then I should see project already shared with group "Ops"
    Then I should see project is not shared with group "Market"

  @javascript
  Scenario: I share project with group
    When I select group "Market" for share
    Then I should see project is shared with group "Market"
