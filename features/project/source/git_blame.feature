Feature: Project Browse git repo
  Background:
    Given I sign in as a user
    And I own project "Shop"
    Given I visit project source page

  Scenario: I blame file
    Given I click on "Gemfile" file in repo
    And I click blame button
    Then I should see git file blame
