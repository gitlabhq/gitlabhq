Feature: Project Browse branches
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
    When I submit new branch form
    Then I should see new branch created
