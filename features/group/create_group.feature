Feature: Groups
  Background:
    Given I sign in as a user

  Scenario: Create a group from dasboard
    Given I have group with projects
    And I visit dashboard page
    When I click new group link
    And submit form with new group info
    Then I should be redirected to group page
    And I should see newly created group
