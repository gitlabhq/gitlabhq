@dashboard
Feature: Event filters
  Background:
    Given I sign in as a user
    And I own a project
    And this project has push event
    And this project has new member event
    And this project has merge request event
    And I visit dashboard page

  @javascript
  Scenario: I should see all events
    Then I should see push event
    And I should see new member event
    And I should see merge request event

  @javascript
  Scenario: I should see only pushed events
    When I click "push" event filter 
    Then I should see push event
    And I should not see new member event
    And I should not see merge request event

  @javascript
  Scenario: I should see only joined events
    When I click "team" event filter
    Then I should see new member event
    And I should not see push event
    And I should not see merge request event

  @javascript
  Scenario: I should see only merged events
    When I click "merge" event filter
    Then I should see merge request event
    And I should not see push event
    And I should not see new member event

  @javascript
  Scenario: I should see only selected events while page reloaded
    When I click "push" event filter
    And I visit dashboard page
    Then I should see push event
    And I should not see new member event
    When I click "team" event filter
    And I visit dashboard page
    Then I should see push event
    And I should see new member event
    And I should not see merge request event
    When I click "push" event filter
    Then I should not see push event
    And I should see new member event
    And I should not see merge request event
