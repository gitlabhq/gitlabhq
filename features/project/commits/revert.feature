@project_commits
Feature: Revert Commits
  Background:
    Given I sign in as a user
    And I own a project
    And I visit my project's commits page

  Scenario: I revert a commit
    Given I click on commit link
    And I click on the revert button
    And I revert the changes directly
    Then I should see the revert commit notice

  Scenario: I revert a commit that was previously reverted
    Given I click on commit link
    And I click on the revert button
    And I revert the changes directly
    And I visit my project's commits page
    And I click on commit link
    And I click on the revert button
    And I revert the changes directly
    Then I should see a revert error

  Scenario: I revert a commit in a new merge request
    Given I click on commit link
    And I click on the revert button
    And I revert the changes in a new merge request
    Then I should see the new merge request notice
