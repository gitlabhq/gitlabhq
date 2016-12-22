@admin
Feature: Admin Settings
  Background:
    Given I sign in as an admin
    And I visit admin settings page

  Scenario: Help text
    When I set the help text
    Then I should see the help text
    And I go to help page
    Then I should see the help text
    And I logout
    Then I should see the help text
