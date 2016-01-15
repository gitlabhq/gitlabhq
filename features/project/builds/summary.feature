Feature: Project Builds Summary
  Background:
    Given I sign in as a user
    And I own a project
    And CI is enabled
    And I have recent build for my project

  Scenario: I browse build summary page
    When I visit recent build summary page
    Then I see summary for build
    And I see build trace
