Feature: Admin Users
  Background:
    Given I sign in as an admin
    And system has users

  Scenario: On Admin Users
    Given I visit admin users page
    Then I should see all users
