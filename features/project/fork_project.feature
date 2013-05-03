Feature: Fork Project
  Background:
    Given I sign in as a user
    And I am a member of project "Shop"
    When I visit project "Shop" page

  Scenario: User fork a project
    Given I click link "Fork"
    Then I should see the forked project page

  Scenario: User already has forked the project
    Given I already have a project named "Shop" in my namespace
    And I click link "Fork"
    Then I should see a "Name has already been taken" warning
