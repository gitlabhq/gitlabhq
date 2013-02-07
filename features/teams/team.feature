Feature: UserTeams
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has push event

  Scenario: No teams, no dashboard info block
    When I do not have teams with me
    And I visit dashboard page
    Then I should see dashboard page without teams info block

  Scenario: I should see teams info block
    When I have teams with my membership
    And I visit dashboard page
    Then I should see dashboard page with teams information block

  Scenario: I should can create new team
    When I have teams with my membership
    And I visit dashboard page
    When I click to "New team" link
    And I submit form with new team info
    Then I should be redirected to new team page

  Scenario: I should see team dashboard list
    When I have teams with projects and members
    When I visit team page
    Then I should see projects list

  Scenario: I should see team issues list
    Given I have team with projects and members
    And project from team has issues assigned to me
    When I visit team issues page
    Then I should see issues from this team assigned to me

  Scenario: I should see teams members issues list
    Given I have team with projects and members
    Given project from team has issues assigned to teams members
    When I visit team issues page
    Then I should see issues from this team assigned to teams members

  Scenario: I should see team merge requests list
    Given I have team with projects and members
    Given project from team has merge requests assigned to me
    When I visit team merge requests page
    Then I should see merge requests from this team assigned to me

  Scenario: I should see teams members merge requests list
    Given I have team with projects and members
    Given project from team has merge requests assigned to team members
    When I visit team merge requests page
    Then I should see merge requests from this team assigned to me

  Scenario: I should add user to projects in Team
    Given I have team with projects and members
    Given I have new user "John"
    When I visit team people page
    When I click link "New Team Member"
    And I select user "John" from list with role "Reporter"
    Then I should see user "John" in team list

  Scenario: I should assign my team to my own project
    Given I have team with projects and members
    And I have my own project without teams
    And I visit my team page
    When I click on link "Projects"
    And I click link "Assign project to Team"
    Then I should see form with my own project in avaliable projects list
    When I submit form with selected project and max access
    Then I should see my own project in team projects list
