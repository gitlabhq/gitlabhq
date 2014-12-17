Feature: Groups Management
  Background:
    Given "Pete Peters" is owner of group "Sourcing"
    And "Open" is in group "Sourcing"
    And "Mary Jane" has master access for project "Open"

  Scenario: Project master can add members before lock
    Given I sign in as "Mary Jane"
    And I go to "Open" project members page
    Then I can control user membership
    When Group membership lock is enabled
    And I reload "Open" project members page
    Then I cannot control user membership from project page
    And I logout

  Scenario: Group owner lock membership controls
    Given I sign in as "Pete Peters"
    And I go to group settings page
    And I enable membership lock
    And I go to project settings
    Then I cannot control user membership from project page
    And I logout
