@dashboard
Feature: Dashboard Projects
  Background:
    Given I sign in as a user
    And I own project "Forum"
    And I starred project "Forum"
    And public project "Community"
    And I am member of a project "Community" with a guest role
    And I starred project "Community"
    And I own project "Shop"
    And project "Shop" has push event
    And project "Community" has push event
    And "John Doe" starred project "Community"
    And I visit dashboard projects page

  Scenario: I should see projects list
    Then I should see "Your projects"
    Then I should see "Starred projects"
    Then I should see "Community" project link
    Then I should see "Forum" project link
    Then I should see "Shop" project link

  Scenario: I sort projects by recent activity
    And I sort projects list by "Recently active"
    Then I should see "Community" at the top

  Scenario: I sort projects by most stars
    And I sort projects list by "Most stars"
    Then I should see "Community" at the top

  Scenario: I sort projects by Name
    And I sort projects list by "Name"
    Then I should see "Community" at the top

  Scenario: I filter to see only my own projects, I should see projects list
    And I filter to see only my own projects
    Then I should not see "Community" project link
    Then I should see "Forum" project link
    Then I should see "Shop" project link

  Scenario: I filter to see only my own projects, I sort projects by recent activity
    And I filter to see only my own projects
    And I sort projects list by "Recently active"
    Then I should see "Shop" at the top

  Scenario: I filter to see only my own projects, I sort projects by most stars
    And I filter to see only my own projects
    And I sort projects list by "Most stars"
    Then I should see "Forum" at the top

  Scenario: I filter to see only my own projects, I sort projects by Name
    And I filter to see only my own projects
    And I sort projects list by "Name"
    Then I should see "Forum" at the top
