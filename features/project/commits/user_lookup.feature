@project_commits
Feature: Project Commits User Lookup
  Background:
    Given I sign in as a user
    And I own a project
    And I visit my project's commits page

  Scenario: I browse commit from list
    Given I have user with primary email
    When I click on commit link
    Then I see author based on primary email

  Scenario: I browse another commit from list
    Given I have user with secondary email
    When I click on another commit link
    Then I see author based on secondary email
