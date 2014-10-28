Feature: Git Hooks
  Background:
    Given I sign in as a user
    And I own project "Shop"

  Scenario: I should see git hook form
    When I visit project git hooks page
    Then I should see git hook form