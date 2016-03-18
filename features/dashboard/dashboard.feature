@dashboard
Feature: Dashboard
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has push event
    And project "Shop" has CI enabled
    And project "Shop" has CI build
    And I visit dashboard page

  Scenario: I should see projects list
    Then I should see "New Project" link
    Then I should see "Shop" project link
    Then I should see "Shop" project CI status

  @javascript
  Scenario: I should see activity list
    And I visit dashboard activity page
    Then I should see project "Shop" activity feed

  Scenario: I should see groups list
    Given I have group with projects
    And I visit dashboard page
    Then I should see groups list

  @javascript
  Scenario: I should see last push widget
    Then I should see last push widget
    And I click "Create Merge Request" link
    Then I see prefilled new Merge Request page

  @javascript
  Scenario: I should see User joined Project event
    Given user with name "John Doe" joined project "Shop"
    When I visit dashboard activity page
    Then I should see "John Doe joined project Shop" event

  @javascript
  Scenario: I should see User left Project event
    Given user with name "John Doe" joined project "Shop"
    And user with name "John Doe" left project "Shop"
    When I visit dashboard activity page
    Then I should see "John Doe left project Shop" event

  @javascript
  Scenario: Sorting Issues
    Given I visit dashboard issues page
    And I sort the list by "Oldest updated"
    And I visit dashboard activity page
    And I visit dashboard issues page
    Then The list should be sorted by "Oldest updated"

  @javascript
  Scenario: Visiting Project's issues after sorting
    Given I visit dashboard issues page
    And I sort the list by "Oldest updated"
    And I visit project "Shop" issues page
    Then The list should be sorted by "Oldest updated"

  @javascript
  Scenario: Sorting Merge Requests
    Given I visit dashboard merge requests page
    And I sort the list by "Oldest updated"
    And I visit dashboard activity page
    And I visit dashboard merge requests page
    Then The list should be sorted by "Oldest updated"

  @javascript
  Scenario: Visiting Project's merge requests after sorting
    Given I visit dashboard merge requests page
    And I sort the list by "Oldest updated"
    And I visit project "Shop" merge requests page
    Then The list should be sorted by "Oldest updated"
