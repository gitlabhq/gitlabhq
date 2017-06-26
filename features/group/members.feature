Feature: Group Members
  Background:
    Given I sign in as "John Doe"
    And "John Doe" is owner of group "Owned"
    And "John Doe" is guest of group "Guest"

  Scenario: Guest should not be able to remove other users from group
    Given "Mary Jane" is guest of group "Guest"
    When I visit group "Guest" members page
    Then I should see user "John Doe" in team list
    Then I should see user "Mary Jane" in team list
    Then I should not see the "Remove User From Group" button for "Mary Jane"

  Scenario: Search member by name
    Given "Mary Jane" is guest of group "Guest"
    And I visit group "Guest" members page
    When I search for 'Mary' member
    Then I should see user "Mary Jane" in team list
    Then I should not see user "John Doe" in team list
