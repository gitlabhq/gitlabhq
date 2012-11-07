Feature: Admin Groups
  Background:
    Given I sign in as an admin
    And I visit admin groups page

  Scenario: Create a group
    When I click new group link
    And submit form with new group info
    Then I should be redirected to group page
    And I should see newly created group
