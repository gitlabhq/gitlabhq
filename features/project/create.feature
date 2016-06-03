@project-create
Feature: Project Create
  In order to get access to project sections
  A user with ability to create a project
  Should be able to create a new one

  @javascript
  Scenario: User create a project
    Given I sign in as a user
    When I visit new project page
    And I have an ssh key
    And fill project form with valid data
    Then I should see project page
    And I should see empty project instuctions

  @javascript
  Scenario: Empty project instructions
    Given I sign in as a user
    And I have an ssh key
    When I visit new project page
    And fill project form with valid data
    Then I see empty project instuctions
    And I click on HTTP
    Then Remote url should update to http link
    And If I click on SSH
    Then Remote url should update to ssh link
