Feature: Project Builds
  Background:
    Given I sign in as a user
    And I own a project
    And CI is enabled
    And I have recent build for my project

  Scenario: I browse build summary page
    When I visit recent build summary page
    Then I see summary for build
    And I see build trace

  Scenario: I download build artifacts
    Given recent build has artifacts available
    When I visit recent build summary page
    And I click artifacts download button
    Then download of build artifacts archive starts

  Scenario: I browse build artifacts
    Given recent build has artifacts available
    And recent build has artifacts metadata available
    When I visit recent build summary page
    And I click artifacts browse button
    Then I should see content of artifacts archive

  Scenario: I browse subdirectory of build artifacts
    Given recent build has artifacts available
    And recent build has artifacts metadata available
    When I visit recent build summary page
    And I click artifacts browse button
    And I click link to subdirectory within build artifacts
    Then I should see content of subdirectory within artifacts archive
