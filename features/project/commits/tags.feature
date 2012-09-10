Feature: Project Browse tags
  Background:
    Given I sign in as a user
    And I own project "Shop"
    Given I visit project tags page

  Scenario: I can see all git tags
    Then I should see "Shop" all tags list

  # @wip
  # Scenario: I can download project by tag
