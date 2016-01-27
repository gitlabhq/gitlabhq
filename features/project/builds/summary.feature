Feature: Project Builds Summary
  Background:
    Given I sign in as a user
    And I own a project
    And project has CI enabled
    And project has a recent build

  Scenario: I browse build details page
    When I visit recent build details page
    Then I see details of a build
    And I see build trace

  Scenario: I browse project builds page
    When I visit project builds page
    Then I see button to CI Lint
