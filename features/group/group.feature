Feature: Groups
  Background:
    Given I sign in as a user
    And I have group with projects

  @javascript
  Scenario: I should see group dashboard list
    When I visit group page
    Then I should see projects list
    And I should see projects activity feed

  Scenario: I should see group issues list
    Given project from group has issues assigned to me
    When I visit group issues page
    Then I should see issues from this group assigned to me

  Scenario: I should see group merge requests list
    Given project from group has merge requests assigned to me
    When I visit group merge requests page
    Then I should see merge requests from this group assigned to me

  Scenario: I should add user to projects in Group
    Given I have new user "John"
    When I visit group people page
    And I select user "John" from list with role "Reporter"
    Then I should see user "John" in team list

  Scenario: I should see edit group page
    When I visit group settings page
    And I change group name
    Then I should see new group name

