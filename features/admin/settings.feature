@admin
Feature: Admin Settings
  Background:
    Given I sign in as an admin
    And I visit admin settings page

  Scenario: Change application settings
    When I modify settings and save form
    Then I should see application settings saved
