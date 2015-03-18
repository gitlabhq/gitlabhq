@dashboard
Feature: Dashboard Starred Projects
  Background:
    Given I sign in as a user
    And public project "Community"
    And I starred project "Community"
    And I own project "Shop"
    And I visit dashboard starred projects page

  Scenario: I should see projects list
    Then I should see project "Community"
    And I should not see project "Shop"
