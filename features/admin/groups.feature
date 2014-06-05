@admin
Feature: Admin Groups
  Background:
    Given I sign in as an admin
    And I have group with projects
    And User "John Doe" exists
    And I visit admin groups page

  Scenario: See group list
    Then I should be all groups

  Scenario: Create a group
    When I click new group link
    And submit form with new group info
    Then I should be redirected to group page
    And I should see newly created group

  @javascript
  Scenario: Add user into projects in group
    When I visit admin group page
    When I select user "John Doe" from user list as "Reporter"
    Then I should see "John Doe" in team list in every project as "Reporter"
