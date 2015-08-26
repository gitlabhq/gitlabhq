@admin
Feature: Admin Projects
  Background:
    Given I sign in as an admin
    And there are projects in system

  Scenario: I should see non-archived projects in the list
    Given archived project "Archive"
    When I visit admin projects page
    Then I should see all non-archived projects
    And I should not see project "Archive"

  Scenario: I should see all projects in the list
    Given archived project "Archive"
    When I visit admin projects page
    And I check "Show archived projects"
    Then I should see all projects
    And I should see "archived" label

  Scenario: Projects show
    When I visit admin projects page
    And I click on first project
    Then I should see project details

  Scenario: Transfer project
    Given group 'Web'
    And I visit admin project page
    When I transfer project to group 'Web'
    Then I should see project transfered
