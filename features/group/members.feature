Feature: Group Members
  Background:
    Given I sign in as "John Doe"
    And "John Doe" is owner of group "Owned"
    And "John Doe" is guest of group "Guest"

  # Remove others

  Scenario: Owner should be able to remove other users from group
    Given "Mary Jane" is owner of group "Owned"
    When I visit group "Owned" members page
    Then I should see user "John Doe" in team list
    Then I should see user "Mary Jane" in team list
    When I click on the "Remove User From Group" button for "Mary Jane"
    When I visit group "Owned" members page
    Then I should see user "John Doe" in team list
    Then I should not see user "Mary Jane" in team list

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
