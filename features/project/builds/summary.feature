Feature: Project Builds Summary
  Background:
    Given I sign in as a user
    And I own a project
    And project has CI enabled
    And project has a recent build

  Scenario: I browse build summary page
    When I visit recent build summary page
    Then I see summary for build
    And I see build trace
