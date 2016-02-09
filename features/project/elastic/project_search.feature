Feature: Project Search
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And Elasticsearch is enabled

  Scenario: I search through the all project items
    Given project has all data available for the search
    And I visit my project's home page
    Then I search "initial"
    And I find an Issue
    And I find a Merge Request
    And I find a Milestone
    And I find a Comment
    And I find a Commit
    And I find a Wiki Page
    Then I visit my project's home page
    Then I search "def"
    And I find a Code
