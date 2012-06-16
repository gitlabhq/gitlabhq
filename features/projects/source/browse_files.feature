Feature: Browse git repo
  Background: 
    Given I signin as a user
    And I own project "Shop"
    Given I visit project source page

  Scenario: I browse files from master branch
    Then I should see files from repository

  Scenario: I browse files for specific ref
    Given I visit project source page for "8470d70"
    Then I should see files from repository for "8470d70"

  Scenario: I browse file content
    Given I click on file from repo
    Then I should see it content

  Scenario: I browse raw file
    Given I visit blob file from repo 
    And I click on raw button
    Then I should see raw file content


