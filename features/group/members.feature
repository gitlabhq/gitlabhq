Feature: Group Members
  Background:
    Given I sign in as "John Doe"
    And "John Doe" is owner of group "Owned"
    And "John Doe" is guest of group "Guest"

  @javascript
  Scenario: I should add user to group "Owned"
    Given User "Mary Jane" exists
    When I visit group "Owned" members page
    And I select user "Mary Jane" from list with role "Reporter"
    Then I should see user "Mary Jane" in team list

  @javascript
  Scenario: Add user to group
    Given gitlab user "Mike"
    When I visit group "Owned" members page
    When I select "Mike" as "Reporter"
    Then I should see "Mike" in team list as "Reporter"

  @javascript
  Scenario: Ignore add user to group when is already Owner
    Given gitlab user "Mike"
    When I visit group "Owned" members page
    When I select "Mike" as "Reporter"
    Then I should see "Mike" in team list as "Owner"

  @javascript
  Scenario: Invite user to group
    When I visit group "Owned" members page
    When I select "sjobs@apple.com" as "Reporter"
    Then I should see "sjobs@apple.com" in team list as invited "Reporter"

  @javascript
  Scenario: Edit group member permissions
    Given "Mary Jane" is guest of group "Owned"
    And I visit group "Owned" members page
    When I change the "Mary Jane" role to "Developer"
    Then I should see "Mary Jane" as "Developer"

  # Leave

  @javascript
  Scenario: Owner should be able to remove himself from group if he is not the last owner
    Given "Mary Jane" is owner of group "Owned"
    When I visit group "Owned" members page
    Then I should see user "John Doe" in team list
    Then I should see user "Mary Jane" in team list
    When I click on the "Remove User From Group" button for "John Doe"
    And I visit group "Owned" members page
    Then I should not see user "John Doe" in team list
    Then I should see user "Mary Jane" in team list

  @javascript
  Scenario: Owner should not be able to remove himself from group if he is the last owner
    Given "Mary Jane" is guest of group "Owned"
    When I visit group "Owned" members page
    Then I should see user "John Doe" in team list
    Then I should see user "Mary Jane" in team list
    Then I should not see the "Remove User From Group" button for "John Doe"

  @javascript
  Scenario: Guest should be able to remove himself from group
    Given "Mary Jane" is guest of group "Guest"
    When I visit group "Guest" members page
    Then I should see user "John Doe" in team list
    Then I should see user "Mary Jane" in team list
    When I click on the "Remove User From Group" button for "John Doe"
    When I visit group "Guest" members page
    Then I should not see user "John Doe" in team list
    Then I should see user "Mary Jane" in team list

  @javascript
  Scenario: Guest should be able to remove himself from group even if he is the only user in the group
    When I visit group "Guest" members page
    Then I should see user "John Doe" in team list
    When I click on the "Remove User From Group" button for "John Doe"
    When I visit group "Guest" members page
    Then I should not see user "John Doe" in team list

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
