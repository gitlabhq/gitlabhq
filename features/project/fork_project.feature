Feature: Fork Project
  In order to get a personal fork of a project
  A user with ability to fork a project
  Should be able to fork a project into their own namespace

  Scenario: User fork a project
    Given I sign in as a user
    And I am a member of project "Shop"
    When I visit project "Shop" page
    And I click link "Fork"
    Then I should see the forked project page
    And I should see a non-empty project page

  Scenario: User already has forked the project
    Given I sign in as a user
    And I already have a project named "Shop" in my namespace
    When I visit project "Shop" page
    And I click link "Fork"
    Then I should see a "Name has already been taken" warning
