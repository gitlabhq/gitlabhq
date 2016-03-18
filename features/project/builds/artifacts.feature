Feature: Project Builds Artifacts
  Background:
    Given I sign in as a user
    And I own a project
    And project has CI enabled
    And project has a recent build

  Scenario: I download build artifacts
    Given recent build has artifacts available
    When I visit recent build details page
    And I click artifacts download button
    Then download of build artifacts archive starts

  Scenario: I browse build artifacts
    Given recent build has artifacts available
    And recent build has artifacts metadata available
    When I visit recent build details page
    And I click artifacts browse button
    Then I should see content of artifacts archive

  Scenario: I browse subdirectory of build artifacts
    Given recent build has artifacts available
    And recent build has artifacts metadata available
    When I visit recent build details page
    And I click artifacts browse button
    And I click link to subdirectory within build artifacts
    Then I should see content of subdirectory within artifacts archive

  Scenario: I browse directory with UTF-8 characters in name
    Given recent build has artifacts available
    And recent build has artifacts metadata available
    And recent build artifacts contain directory with UTF-8 characters
    When I visit recent build details page
    And I click artifacts browse button
    And I navigate to directory with UTF-8 characters in name
    Then I should see content of directory with UTF-8 characters in name

  Scenario: I try to browse directory with invalid UTF-8 characters in name
    Given recent build has artifacts available
    And recent build has artifacts metadata available
    And recent build artifacts contain directory with invalid UTF-8 characters
    When I visit recent build details page
    And I click artifacts browse button
    And I navigate to parent directory of directory with invalid name
    Then I should not see directory with invalid name on the list

  Scenario: I download a single file from build artifacts
    Given recent build has artifacts available
    And recent build has artifacts metadata available
    When I visit recent build details page
    And I click artifacts browse button
    And I click a link to file within build artifacts
    Then download of a file extracted from build artifacts should start

  @javascript
  Scenario: I click on a row in an artifacts table
    Given recent build has artifacts available
    And recent build has artifacts metadata available
    When I visit recent build details page
    And I click artifacts browse button
    And I click a first row within build artifacts table
    Then page with a coresponding path is loading
