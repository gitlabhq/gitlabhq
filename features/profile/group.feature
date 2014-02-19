Feature: Profile Group
  Background:
    Given I sign in as "John Doe"
    And "John Doe" is owner of group "Owned"
    And "John Doe" is guest of group "Guest"

  # Leave groups

  @javascript
  Scenario: Owner should be able to leave from group if he is not the last owner
    Given "Mary Jane" is owner of group "Owned"
    When I visit profile groups page
    Then I should see group "Owned" in group list
    Then I should see group "Guest" in group list
    When I click on the "Leave" button for group "Owned"
    And I visit profile groups page
    Then I should not see group "Owned" in group list
    Then I should see group "Guest" in group list

  @javascript
  Scenario: Owner should not be able to leave from group if he is the last owner
    Given "Mary Jane" is guest of group "Owned"
    When I visit profile groups page
    Then I should see group "Owned" in group list
    Then I should see group "Guest" in group list
    Then I should not see the "Leave" button for group "Owned"

  @javascript
  Scenario: Guest should be able to leave from group
    Given "Mary Jane" is guest of group "Guest"
    When I visit profile groups page
    Then I should see group "Owned" in group list
    Then I should see group "Guest" in group list
    When I click on the "Leave" button for group "Guest"
    When I visit profile groups page
    Then I should see group "Owned" in group list
    Then I should not see group "Guest" in group list

  @javascript
  Scenario: Guest should be able to leave from group even if he is the only user in the group
    When I visit profile groups page
    Then I should see group "Owned" in group list
    Then I should see group "Guest" in group list
    When I click on the "Leave" button for group "Guest"
    When I visit profile groups page
    Then I should see group "Owned" in group list
    Then I should not see group "Guest" in group list
