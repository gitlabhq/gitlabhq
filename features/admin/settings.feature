@admin
Feature: Admin Settings
  Background:
    Given I sign in as an admin
    And I visit admin settings page

  Scenario: Change application settings
    When I modify settings and save form
    Then I should see application settings saved

  Scenario: Help text
    When I set the help text
    Then I should see the help text
    And I go to help page
    Then I should see the help text
    And I logout
    Then I should see the help text

  Scenario: Change Slack Service Template settings
    When I click on "Service Templates"
    And I click on "Slack" service
    And I fill out Slack settings
    Then I check all events and submit form
    And I should see service template settings saved
    Then I click on "Slack" service
    And I should see all checkboxes checked
    And I should see Slack settings saved
