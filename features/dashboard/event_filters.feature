Feature: Event filters
  Background:
    Given I sign in as a user
    And I own a project
    And this project has push event
    And this project has new member event
    And this project has merge request event
    And I visit dashboard page

  Scenario: I should see all events
    Then I should see push event
    Then I should see new member event
    Then I should see merge request event

