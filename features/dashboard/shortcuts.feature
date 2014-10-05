@dashboard
Feature: Dashboard Shortcuts
  Background:
    Given I sign in as a user
    And I visit dashboard page

  @javascript
  Scenario: Navigate to projects tab
    Given I press "g" and "p"
    Then the active main tab should be Projects

  @javascript
  Scenario: Navigate to issue tab
    Given I press "g" and "i"
    Then the active main tab should be Issues

  @javascript
  Scenario: Navigate to merge requests tab
    Given I press "g" and "m"
    Then the active main tab should be Merge Requests

