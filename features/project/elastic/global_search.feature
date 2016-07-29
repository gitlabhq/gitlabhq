Feature: Global Search
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And Elasticsearch is enabled

  Scenario: I search through the all projects
    Given project has all data available for the search
    And I visit dashboard page
    Then I search "initial"
    And I find an Issue
    And I find a Merge Request
    And I find a Milestone