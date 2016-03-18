@dashboard
Feature: Project Find File
  Background:
    Given I sign in as a user
    And I own a project
    And I visit my project's files page

  @javascript
  Scenario: Navigate to find file by shortcut
    Given I press "t"
    Then I should see "find file" page

  Scenario: Navigate to find file
    Given I click Find File button
    Then I should see "find file" page

  @javascript
  Scenario: I search file
    Given I visit project find file page
    And I fill in file find with "change"
    Then I should not see ".gitignore" in files
    And I should not see ".gitmodules" in files
    And I should see "CHANGELOG" in files
    And I should not see "VERSION" in files

  @javascript
  Scenario: I search file that not exist
    Given I visit project find file page
    And I fill in file find with "asdfghjklqwertyuizxcvbnm"
    Then I should not see ".gitignore" in files
    And I should not see ".gitmodules" in files
    And I should not see "CHANGELOG" in files
    And I should not see "VERSION" in files

  @javascript
  Scenario: I search file that partially matches
    Given I visit project find file page
    And I fill in file find with "git"
    Then I should see ".gitignore" in files
    And I should see ".gitmodules" in files
    And I should not see "CHANGELOG" in files
    And I should not see "VERSION" in files
