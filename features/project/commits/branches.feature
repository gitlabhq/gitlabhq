@project_commits
Feature: Project Commits Branches
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has protected branches

  Scenario: I can see project all git branches
    Given I visit project branches page
    Then I should see "Shop" all branches list

  Scenario: I can see project protected git branches
    Given I visit project protected branches page
    Then I should see "Shop" protected branches list

  Scenario: I create a branch
    Given I visit project branches page
    And I click new branch link
    And I submit new branch form
    Then I should see new branch created

  @javascript
  Scenario: I delete a branch
    Given I visit project branches page
    And I filter for branch improve/awesome
    And I click branch 'improve/awesome' delete link
    Then I should not see branch 'improve/awesome'

  @javascript
  Scenario: I create a branch with invalid name
    Given I visit project branches page
    And I click new branch link
    And I submit new branch form with invalid name
    Then I should see new an error that branch is invalid

  Scenario: I create a branch with invalid reference
    Given I visit project branches page
    And I click new branch link
    And I submit new branch form with invalid reference
    Then I should see new an error that ref is invalid

  Scenario: I create a branch that already exists
    Given I visit project branches page
    And I click new branch link
    And I submit new branch form with branch that already exists
    Then I should see new an error that branch already exists
