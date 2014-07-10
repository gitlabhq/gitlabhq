Feature: Project Issue Tracker
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has issues enabled
    And I visit project "Shop" page

  Scenario: I set the issue tracker to "GitLab"
    When I visit edit project "Shop" page
    And change the issue tracker to "GitLab"
    And I save project
    Then I the project should have "GitLab" as issue tracker

  Scenario: I set the issue tracker to "Redmine"
    When I visit edit project "Shop" page
    And change the issue tracker to "Redmine"
    And I save project
    Then I the project should have "Redmine" as issue tracker
