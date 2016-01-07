@project-stars
Feature: Project Star
  Scenario: New projects have 0 stars
    Given public project "Community"
    When I visit project "Community" page
    Then The project has no stars

  Scenario: Empty projects show star count
    Given public empty project "Empty Public Project"
    When I visit empty project page
    Then The project has no stars

  Scenario: Signed off users can't star projects
    Given public project "Community"
    And I visit project "Community" page
    When I click on the star toggle button
    Then I redirected to sign in page

  @javascript
  Scenario: Signed in users can toggle star
    Given I sign in as "John Doe"
    And public project "Community"
    And I visit project "Community" page
    When I click on the star toggle button
    Then The project has 1 star
    When I click on the star toggle button
    Then The project has 0 stars

  @javascript
  Scenario: Star count sums stars
    Given I sign in as "John Doe"
    And public project "Community"
    And I visit project "Community" page
    And I click on the star toggle button
    And I logout
    And I sign in as "Mary Jane"
    And I visit project "Community" page
    When I click on the star toggle button
    Then The project has 2 stars
