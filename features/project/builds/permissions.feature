Feature: Project Builds Permissions
  Background:
    Given I sign in as a user
    And project exists in some group namespace
    And project has CI enabled
    And project has a recent build

  Scenario: I try to download build artifacts as guest
    Given I am member of a project with a guest role
    And recent build has artifacts available
    When I access artifacts download page
    Then page status code should be 404

  Scenario: I try to download build artifacts as reporter
    Given I am member of a project with a reporter role
    And recent build has artifacts available
    When I access artifacts download page
    Then download of build artifacts archive starts
