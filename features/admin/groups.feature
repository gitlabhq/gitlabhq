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

  @javascript
  Scenario: Remove user from group
    Given we have user "John Doe" in group
    When I visit admin group page
    And I remove user "John Doe" from group
    Then I should not see "John Doe" in team list

  @javascript
  Scenario: Invite user to a group by e-mail
    When I visit admin group page
    When I select user "johndoe@gitlab.com" from user list as "Reporter"
    Then I should see "johndoe@gitlab.com" in team list in every project as "Reporter"

  @javascript
  Scenario: Signed in admin should be able to add himself to a group
    Given "John Doe" is owner of group "Owned"
    When I visit group "Owned" members page
    When I select current user as "Developer"
    Then I should see current user as "Developer"

  @javascript
  Scenario: Signed in admin should be able to remove himself from group
    Given current user is developer of group "Owned"
    When I visit group "Owned" members page
    Then I should see current user as "Developer"
    When I click on the "Remove User From Group" button for current user
    When I visit group "Owned" members page
    Then I should not see current user as "Developer"
