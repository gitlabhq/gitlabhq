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

  @javascript
  Scenario: I should see project activity
    When I visit project "Shop" page
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

  Scenario: I should see project readme and version
    When I visit project "Shop" page
    And I should see project "Shop" version

  Scenario: I should change project default branch
    When I visit edit project "Shop" page
    And change project default branch
    And I save project
    Then I should see project default branch changed

  @javascript
  Scenario: I should have default tab per my preference
    And I own project "Forum"
    When I select project "Forum" README tab
    Then I should see project "Forum" README
    And I visit project "Shop" page
    Then I should see project "Shop" README
