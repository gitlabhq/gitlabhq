@admin
Feature: Admin Settings
  Background:
    Given I sign in as an admin
    And I visit admin settings page

  Scenario: Change application settings
    When I disable gravatars and save form
    Then I should be see gravatar disabled
