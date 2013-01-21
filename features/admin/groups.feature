Feature: Admin Groups
  Background:
    Given I sign in as an admin
    And I have group with projects
    And Create gitlab user "John"
    And I visit admin groups page

  Scenario: Create a group
    When I click new group link
    And submit form with new group info
    Then I should be redirected to group page
    And I should see newly created group

  Scenario: Add user into projects in group
    When I visit admin group page
    When I select user "John" from user list as "Reporter"
    Then I should see "John" in team list in every project as "Reporter"
