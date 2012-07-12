Feature: Create Project
  In order to get access to project sections
  A user with ability to create a project
  Should be able to create a new one

  Scenario: User create a project
    Given I signin as a user
    When I visit new project page
    And fill project form with valid data
    Then I should see project page
    And I should see empty project instuctions

  Scenario: User create a project, changing the initial access
    Given I signin as a user
    And gitlab admin "Sam"
    When I visit new project page
    And fill project form with valid data and change initial access
    Then I should see project page for "NewOpenProject"
    When I visit project "NewOpenProject" team page
    Then I should see myself in team list as "Master"
    Then I should see "Sam" in team list as "Developer"
