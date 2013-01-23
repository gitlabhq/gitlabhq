Feature: Admin Teams
  Background:
    Given I sign in as an admin
    And Create gitlab user "John"

  Scenario: Create a team
    When I visit admin teams page
    And I click new team link
    And submit form with new team info
    Then I should be redirected to team page
    And I should see newly created team

  Scenario: Add user to team
    When I visit admin teams page
    When I have clean "HardCoders" team
    And I visit "HardCoders" team page
    When I click to "Add members" link
    When I select user "John" from user list as "Developer"
    And submit form with new team member info
    Then I should see "John" in teams members list as "Developer"

  Scenario: Assign team to existing project
    When I visit admin teams page
    When I have "HardCoders" team with "John" member with "Developer" role
    When I have "Shop" project
    And I visit "HardCoders" team page
    Then I should see empty projects table
    When I click to "Add projects" link
    When I select project "Shop" with max access "Reporter"
    And submit form with new team project info
    Then I should see "Shop" project in projects list
    When I visit "Shop" project admin page
    Then I should see "John" user with role "Reporter" in team table

  Scenario: Add user to team with ptojects
    When I visit admin teams page
    When I have "HardCoders" team with "John" member with "Developer" role
    And "HardCoders" team assigned to "Shop" project with "Developer" max role access
    When I have gitlab user "Jimm"
    And I visit "HardCoders" team page
    Then I should see members table without "Jimm" member
    When I click to "Add members" link
    When I select user "Jimm" ub team members list as "Master"
    And submit form with new team member info
    Then I should see "Jimm" in teams members list as "Master"

  Scenario: Remove member from team
    Given I have users team "HardCoders"
    And gitlab user "John" is a member "HardCoders" team
    And gitlab user "Jimm" is a member "HardCoders" team
    And "HardCoders" team is assigned to "Shop" project
    When I visit admin teams page
    When I visit "HardCoders" team admin page
    Then I shoould see "John" in members list
    And I should see "Jimm" in members list
    And I should see "Shop" in projects list
    When I click on remove "Jimm" user link
    Then I should be redirected to "HardCoders" team admin page
    And I should not to see "Jimm" user in members list

  Scenario: Remove project from team
    Given I have users team "HardCoders"
    And gitlab user "John" is a member "HardCoders" team
    And gitlab user "Jimm" is a member "HardCoders" team
    And "HardCoders" team is assigned to "Shop" project
    When I visit admin teams page
    When I visit "HardCoders" team admin page
    Then I should see "Shop" project in projects list
    When I click on "Relegate" link on "Shop" project
    Then I should see projects liston team page without "Shop" project
