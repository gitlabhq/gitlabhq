Feature: Project
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has push event
    And I visit project "Shop" page

  Scenario: I edit the project avatar
    Given I visit edit project "Shop" page
    When I change the project avatar
    And I should see new project avatar
    And I should see the "Remove avatar" button

  Scenario: I remove the project avatar
    Given I visit edit project "Shop" page
    And I have an project avatar
    When I remove my project avatar
    Then I should see the default project avatar
    And I should not see the "Remove avatar" button

  Scenario: I should have back to group button
    And project "Shop" belongs to group
    And I visit project "Shop" page
    Then I should see back to group button

  Scenario: I should have back to group button
    And I visit project "Shop" page
    Then I should see back to dashboard button

  Scenario: I should have readme on page
    And I visit project "Shop" page
    Then I should see project "Shop" README

  Scenario: I should see last commit with CI
    Given project "Shop" has CI enabled
    Given project "Shop" has CI build
    And I visit project "Shop" page
    And I should see last commit with CI status

  @javascript
  Scenario: I should see project activity
    When I visit project "Shop" activity page
    Then I should see project "Shop" activity feed

  Scenario: I visit edit project
    When I visit edit project "Shop" page
    Then I should see project settings

  Scenario: I edit project
    When I visit edit project "Shop" page
    And change project settings
    And I save project
    Then I should see project with new settings

  Scenario: I change project path
    When I visit edit project "Shop" page
    And change project path settings
    Then I should see project with new path settings

  Scenario: I should change project default branch
    When I visit edit project "Shop" page
    And change project default branch
    And I save project
    Then I should see project default branch changed

  Scenario: I tag a project
    When I visit edit project "Shop" page
    Then I should see project settings
    And I add project tags
    And I save project
    Then I should see project tags

  Scenario: I should not see "New Issue" or "New Merge Request" buttons
    Given I disable issues and merge requests in project
    When I visit project "Shop" page
    Then I should not see "New Issue" button
    And I should not see "New Merge Request" button

  Scenario: I should not see Project snippets
    Given I disable snippets in project
    When I visit project "Shop" page
    Then I should not see "Snippets" button

  @javascript
  Scenario: I edit Project Notifications
    Given I click notifications drop down button
    When I choose Mention setting
    Then I should see Notification saved message

  Scenario: I should see command line instructions
    Given I own an empty project
    And I visit my empty project page
    And I create bare repo
    Then I should see command line instructions
