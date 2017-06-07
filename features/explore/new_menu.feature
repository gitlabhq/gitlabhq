@explore
Feature: New Menu
Background:
  Given I sign in as "John Doe"
  And "John Doe" is owner of group "Owned"
  And I own project "Shop"
  And I visit dashboard page

  @javascript
  Scenario: I should see New Projects page
    When I visit dashboard page
    And I click "New project" in top right menu
    Then I see "New Project" page

  @javascript
  Scenario: I should see New Group page
    When I visit dashboard page
    And I click "New group" in top right menu
    Then I see "New Group" page

  @javascript
  Scenario: I should see New Snippet page
    When I visit dashboard page
    And I click "New snippet" in top right menu
    Then I see "New Snippet" page

  @javascript
  Scenario: I should see New Issue page
    When I visit project "Shop" page
    And I click "New issue" in top right menu
    Then I see "New Issue" page

  @javascript
  Scenario: I should see New Merge Request page
    When I visit project "Shop" page
    And I click "New merge request" in top right menu
    Then I see "New Merge Request" page

  @javascript
  Scenario: I should see New Project Snippet page
    When I visit project "Shop" page
    And I click "New project snippet" in top right menu
    Then I see "New Snippet" page

  @javascript
  Scenario: I should see New Group Project page
    When I visit group "Owned" page
    And I click "New group project" in top right menu
    Then I see "New Project" page

  @javascript
  Scenario: I should see New Subgroup page
    When I visit group "Owned" page
    And I click "New subgroup" in top right menu
    Then I see "New Group" page
