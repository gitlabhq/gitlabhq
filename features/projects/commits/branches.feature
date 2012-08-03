Feature: Browse branches
  Background: 
    Given I signin as a user
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

  Scenario: I can download project by branch

  Scenario: I can view protected branches

  Scenario: I can manage protected branches
