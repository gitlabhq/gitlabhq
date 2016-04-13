@profile
Feature: Profile Notifications
  Background:
    Given I sign in as a user
    And I own project "Shop"

  Scenario: I visit notifications tab
    When I visit profile notifications page
    Then I should see global notifications settings

  @javascript
  Scenario: I edit Project Notifications
    Given I visit profile notifications page
    When I select Mention setting from dropdown
    Then I should see Notification saved message
