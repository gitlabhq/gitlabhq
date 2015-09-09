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

  Scenario: I add new hook with SSL verification enabled
    Given I visit project hooks page
    When I submit new hook with SSL verification enabled
    Then I should see newly created hook with SSL verification enabled

  Scenario: I test hook
    Given project has hook
    And I visit project hooks page
    When I click test hook button
    Then hook should be triggered

  Scenario: I test a hook on empty project
    Given I own empty project with hook
    And I visit project hooks page
    When I click test hook button
    Then I should see hook error message

  Scenario: I test a hook on down URL
    Given project has hook
    And I visit project hooks page
    When I click test hook button with invalid URL
    Then I should see hook service down error message
