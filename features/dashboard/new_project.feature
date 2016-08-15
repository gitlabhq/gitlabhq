@dashboard
Feature: New Project
Background:
  Given I sign in as a user
  And I own project "Shop"
  And I visit dashboard page
  And I click "New project" link

  @javascript
  Scenario: I should see New Projects page
  Then I see "New Project" page
  Then I see all possible import options

  @javascript
  Scenario: I should see instructions on how to import from Git URL
  Given I see "New Project" page
  When I click on "Repo by URL"
  Then I see instructions on how to import from Git URL

  @javascript
  Scenario: I should see instructions on how to import from GitHub
  Given I see "New Project" page
  When I click on "Import project from GitHub"
  Then I see instructions on how to import from GitHub

  @javascript
  Scenario: I should see Google Code import page
  Given I see "New Project" page
  When I click on "Google Code"
  Then I redirected to Google Code import page
