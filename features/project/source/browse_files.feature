Feature: Project Browse files
  Background:
    Given I sign in as a user
    And I own project "Shop"
    Given I visit project source page

  Scenario: I browse files from master branch
    Then I should see files from repository

  Scenario: I browse files for specific ref
    Given I visit project source page for "8470d70"
    Then I should see files from repository for "8470d70"

  Scenario: I browse file content
    Given I click on "Gemfile.lock" file in repo
    Then I should see it content

  Scenario: I browse raw file
    Given I visit blob file from repo
    And I click link "raw"
    Then I should see raw file content

  Scenario: I can create file
    Given I click on "new file" link in repo
    Then I can see new file page

  @javascript
  Scenario: I can edit file
    Given I click on "Gemfile.lock" file in repo
    And I click button "edit"
    Then I can edit code

  @javascript
  Scenario: I can see editing preview
    Given I click on "Gemfile.lock" file in repo
    And I click button "edit"
    And I edit code
    And I click link "Diff"
    Then I see diff

  Scenario: I can browse directory with Browse Dir
    Given I click on app directory
    And I click on history link
    Then I see Browse dir link

  Scenario: I can browse file with Browse File
    Given I click on readme file
    And I click on history link
    Then I see Browse file link

  Scenario: I can browse code with Browse Code
    Given I click on history link
    Then I see Browse code link
