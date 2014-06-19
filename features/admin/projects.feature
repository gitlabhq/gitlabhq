@admin
Feature: Admin Projects
  Background:
    Given I sign in as an admin
    And there are projects in system

  Scenario: Projects list
    When I visit admin projects page
    Then I should see all projects

  Scenario: Projects show
    When I visit admin projects page
    And I click on first project
    Then I should see project details

  Scenario: Transfer project
    Given group 'Web'
    And I visit admin project page
    When I transfer project to group 'Web'
    Then I should see project transfered
