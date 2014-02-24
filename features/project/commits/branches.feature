Feature: Project Browse branches
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has protected branches
    Given I visit project branches page

  Scenario: I can see project recent git branches
    Then I should see "Shop" recent branches list

  Scenario: I can see project all git branches
    Given I click link "All"
    Then I should see "Shop" all branches list

  Scenario: I can see project protected git branches
    Given I click link "Protected"
    Then I should see "Shop" protected branches list

  Scenario: I create a branch
    Given I click new branch link
    When I submit new branch form
    Then I should see new branch created
