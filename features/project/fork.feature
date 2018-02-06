Feature: Project Fork
  Background:
    Given I sign in as a user
    And I am a member of project "Shop"
    When I visit project "Shop" page

  Scenario: User fork a project
    Given I click link "Fork"
    When I fork to my namespace
    Then I should see the forked project page

  Scenario: User already has forked the project
    Given I already have a project named "Shop" in my namespace
    And I click link "Fork"
    When I fork to my namespace
    Then I should see a "Name has already been taken" warning

  Scenario: Merge request on canonical repo goes to fork merge request page
    Given I click link "Fork"
    And I fork to my namespace
    Then I should see the forked project page
    When I visit project "Shop" page
    Then I should see "New merge request"
    And I goto the Merge Requests page
    Then I should see "New merge request"
    And I click link "New merge request"
    Then I should see the new merge request page for my namespace

  Scenario: Viewing forks of a Project
    Given I click link "Fork"
    When I fork to my namespace
    And I visit the forks page of the "Shop" project
    Then I should see my fork on the list

  Scenario: Viewing forks of a Project that has no repo
    Given I click link "Fork"
    When I fork to my namespace
    And I make forked repo invalid
    And I visit the forks page of the "Shop" project
    Then I should see my fork on the list

  Scenario: Viewing private forks of a Project
    Given There is an existent fork of the "Shop" project
    And I click link "Fork"
    When I fork to my namespace
    And I visit the forks page of the "Shop" project
    Then I should see my fork on the list
    And I should not see the other fork listed
    And I should see a private fork notice
