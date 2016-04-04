Feature: Groups
  Background:
    Given I sign in as "John Doe"
    And "John Doe" is owner of group "Owned"

  Scenario: I should not see a group if it does not exist
    When I visit group "NonExistentGroup" page
    Then page status code should be 404

  @javascript
  Scenario: I should see group "Owned" dashboard list
    When I visit group "Owned" page
    Then I should see group "Owned" projects list

  @javascript
  Scenario: I should see group "Owned" activity feed
    When I visit group "Owned" activity page
    And I should see projects activity feed

  Scenario: I should see group "Owned" issues list
    Given project from group "Owned" has issues assigned to me
    When I visit group "Owned" issues page
    Then I should see issues from group "Owned" assigned to me

  Scenario: I should not see issues from archived project in "Owned" group issues list
    Given Group "Owned" has archived project
    And the archived project have some issues
    When I visit group "Owned" issues page
    Then I should not see issues from the archived project

  Scenario: I should see group "Owned" merge requests list
    Given project from group "Owned" has merge requests assigned to me
    When I visit group "Owned" merge requests page
    Then I should see merge requests from group "Owned" assigned to me

  Scenario: I should not see merge requests from archived project in "Owned" group merge requests list
    Given Group "Owned" has archived project
    And the archived project have some merge_requests
    When I visit group "Owned" merge requests page
    Then I should not see merge requests from the archived project

  Scenario: I should see edit group "Owned" page
    When I visit group "Owned" settings page
    And I change group "Owned" name to "new-name"
    Then I should see new group "Owned" name

  Scenario: I edit group "Owned" avatar
    When I visit group "Owned" settings page
    And I change group "Owned" avatar
    And I visit group "Owned" settings page
    Then I should see new group "Owned" avatar
    And I should see the "Remove avatar" button

  Scenario: I remove group "Owned" avatar
    When I visit group "Owned" settings page
    And I have group "Owned" avatar
    And I visit group "Owned" settings page
    And I remove group "Owned" avatar
    Then I should not see group "Owned" avatar
    And I should not see the "Remove avatar" button

  Scenario: Add new LDAP synchronization
    Given LDAP enabled
    When I visit Group "Owned" LDAP settings page
    And I add a new LDAP synchronization
    Then I see a new LDAP synchronization listed
    And LDAP disabled

  # Group projects in settings
  Scenario: I should see all projects in the project list in settings
    Given Group "Owned" has archived project
    When I visit group "Owned" projects page
    Then I should see group "Owned" projects list
    And I should see "archived" label

  # Public group
  @javascript
  Scenario: Signed out user should see group
    Given "Mary Jane" is owner of group "Owned"
    And I am a signed out user
    And Group "Owned" has a public project "Public-project"
    When I visit group "Owned" page
    Then I should see group "Owned"
    Then I should see project "Public-project"

