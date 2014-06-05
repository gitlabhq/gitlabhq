@dashboard
Feature: Dashboard projects
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And I visit dashboard projects page

  Scenario: I should see projects list
    Then I should see projects list
