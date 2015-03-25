@dashboard
Feature: New Project
Background:
  Given I sign in as a user
  And I own project "Shop"
  And I visit dashboard page

  @javascript
  Scenario: I should see New projects page
  Given I click "New project" link
  Then I see "New project" page
  When I click on "Import project from GitHub"
  Then I see instructions on how to import from GitHub
