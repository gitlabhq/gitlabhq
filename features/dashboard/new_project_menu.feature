@dashboard
Feature: New Project through top menu
Background:
  Given I sign in as a user
  And I own project "Shop"
  And I visit dashboard page
  And I click "New project" in top right menu

  @javascript
  Scenario: I should see New Projects page
  Then I see "New Project" page
