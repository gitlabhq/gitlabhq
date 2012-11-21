Feature: Dashboard
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has push event
    And I visit dashboard page

  Scenario: I should see projects list
    Then I should see "New Project" link
    Then I should see "Shop" project link
    Then I should see project "Shop" activity feed

  Scenario: I should see groups list
    Given I have group with projects
    And I visit dashboard page
    Then I should see groups list

  Scenario: I should see correct projects count
    Given I have group with projects
    And group has a projects that does not belongs to me
    When I visit dashboard page
    Then I should see 1 project at group list

  Scenario: I should see last push widget
    Then I should see last push widget
    And I click "Create Merge Request" link
    Then I see prefilled new Merge Request page

  Scenario: I should see User joined Project event
    Given user with name "John Doe" joined project "Shop"
    When I visit dashboard page
    Then I should see "John Doe joined project at Shop" event

  Scenario: I should see User left Project event
    Given user with name "John Doe" joined project "Shop"
    And user with name "John Doe" left project "Shop"
    When I visit dashboard page
    Then I should see "John Doe left project at Shop" event
