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

  @javascript
  Scenario: Signed in admin should be able to add himself to a project
    Given "John Doe" owns private project "Enterprise"
    When I visit project "Enterprise" members page
    When I select current user as "Developer"
    Then I should see current user as "Developer"

  @javascript
  Scenario: Signed in admin should be able to remove himself from a project
    Given "John Doe" owns private project "Enterprise"
    And current user is developer of project "Enterprise"
    When I visit project "Enterprise" members page
    Then I should see current user as "Developer"
    When I click on the "Remove User From Project" button for current user
    Then I should not see current user as "Developer"
