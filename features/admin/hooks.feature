@admin
Feature: Admin Hooks
  Background:
    Given I sign in as an admin

  Scenario: On Admin Hooks
    Given I visit admin hooks page
    Then I submit the form with enabled SSL verification
    And I see new hook with enabled SSL verification