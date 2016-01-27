Feature: Groups
  Background:
    Given I sign in as "John Doe"
    And "John Doe" is owner of group "Owned"
    And Group "Owned" has a public project "Public-project"
    And Group "Owned" has a public project "Star-project" with 2 stars including 1 from "John Doe"
    And Group "Owned" has an internal project "Moon-project" with 1 star from "John Doe"
    And project "Moon-project" has push event

  Scenario: I should have back to group button
    When I visit group "Owned" page
    Then I should see back to dashboard button

  @javascript
  Scenario: I should see group "Owned" dashboard list
    When I visit group "Owned" page
    And I should see projects activity feed

  # Projects
  Scenario: I should see group "Owned" projects list
    When I visit group "Owned" projects page
    Then I should see a nav block
    Then I should see "All"
    Then I should see "Contributed"
    Then I should see "Starred"
    Then I should see group "Owned" projects list

  Scenario: I sort projects by recent activity
    When I visit group "Owned" projects page
    And I sort projects list by "Recently active"
    Then I should see "Moon-project" at the top

  Scenario: I sort projects by most stars
    When I visit group "Owned" projects page
    And I sort projects list by "Most stars"
    Then I should see "Star-project" at the top

  Scenario: I sort projects by Name
    When I visit group "Owned" projects page
    And I sort projects list by "Name"
    Then I should see "Moon-project" at the top

  Scenario: I should see group "Owned" issues list
    Given project from group "Owned" has issues assigned to me
    When I visit group "Owned" issues page
    Then I should see issues from group "Owned" assigned to me

  Scenario: I should see group "Owned" merge requests list
    Given project from group "Owned" has merge requests assigned to me
    When I visit group "Owned" merge requests page
    Then I should see merge requests from group "Owned" assigned to me

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

  @javascript
  Scenario: I should not see a nav block if group is empty
    And "John Doe" is owner of group "Empty"
    When I visit group "Empty" page
    Then I should not see a nav block

  # Group projects in settings
  Scenario: I should see all projects in the project list in settings
    Given Group "Owned" has archived project
    When I visit group "Owned" projects edit page
    Then I should see group "Owned" projects list
    And I should see "archived" label

  # Public group
  @javascript
  Scenario: Signed out user should see group
    Given "Mary Jane" is owner of group "Owned"
    And I am a signed out user
    When I visit group "Owned" projects page
    Then I should see group "Owned"
    Then I should see "All"
    Then I should see project "Public-project"
