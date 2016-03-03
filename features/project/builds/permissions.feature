Feature: Project Builds Permissions
  Background:
    Given I sign in as a user
    And project exists in some group namespace
    And project has CI enabled
    And project has a recent build

  Scenario: I try to visit build details as guest
    Given I am member of a project with a guest role
    When I visit recent build details page
    Then page status code should be 404

  Scenario: I try to visit project builds page as guest
    Given I am member of a project with a guest role
    When I visit project builds page
    Then page status code should be 404

  Scenario: I try to visit build details of internal project without access to builds
    Given The project is internal
    And public access for builds is disabled
    When I visit recent build details page
    Then page status code should be 404

  Scenario: I try to visit internal project builds page without access to builds
    Given The project is internal
    And public access for builds is disabled
    When I visit project builds page
    Then page status code should be 404

  Scenario: I try to visit build details of internal project with access to builds
    Given The project is internal
    And public access for builds is enabled
    When I visit recent build details page
    Then I see details of a build
    And I see build trace

  Scenario: I try to visit internal project builds page with access to builds
    Given The project is internal
    And public access for builds is enabled
    When I visit project builds page
    Then I see the build

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
