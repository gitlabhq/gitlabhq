Feature: Project Issues Weight
  Background:
    Given I sign in as a user
    And I own project "Shop"
    Given I visit project "Shop" issues page

  Scenario: I should see labels list
    Given I click link "New Issue"
    And I submit new issue "500 error on profile" with weight
    Then I should see issue "500 error on profile" with weight
