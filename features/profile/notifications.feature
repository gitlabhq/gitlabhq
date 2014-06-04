@profile
Feature: Profile Notifications
  Background:
    Given I sign in as a user
    And I own project "Shop"

  Scenario: I visit notifications tab
    When I visit profile notifications page
    Then I should see global notifications settings
