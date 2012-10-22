Feature: Project Hooks
  Background:
    Given I sign in as a user
    And I own project "Shop"

  Scenario: I should see hook list
    Given project has hook
    When I visit project hooks page
    Then I should see project hook

  Scenario: I add new hook
    Given I visit project hooks page
    When I submit new hook
    Then I should see newly created hook

  Scenario: I test hook
    Given project has hook
    And I visit project hooks page
    When I click test hook button
    Then hook should be triggered

