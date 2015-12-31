Feature: Group Hooks
  Background:
    Given I sign in as a user
    And I own group "Sourcing"

  Scenario: I should see hook list
    Given I own project "Shop" in group "Sourcing"
    And group has hook
    When I visit group hooks page
    Then I should see group hook

  Scenario: I add new hook
    GivenI own project "Shop" in group "Sourcing"
    And I visit group hooks page
    When I submit new hook
    Then I should see newly created hook

  Scenario: I test hook
    Given I own project "Shop" in group "Sourcing"
    And group has hook
    And I visit group hooks page
    When I click test hook button
    Then hook should be triggered

  Scenario: I test a hook on empty project
    Given I own empty project "Empty Shop" in group "Sourcing"
    And group has hook
    And I visit group hooks page
    When I click test hook button
    Then I should see hook error message

  Scenario: I test a hook on down URL
    Given I own project "Shop" in group "Sourcing"
    And group has hook
    And I visit group hooks page
    When I click test hook button with invalid URL
    Then I should see hook service down error message
