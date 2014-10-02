Feature: Project Source Search Code
  Background:
    Given I sign in as a user

  Scenario: Search for term "coffee"
    Given I own project "Shop"
    And I visit project source page
    When I search for term "coffee"
    Then I should see files from repository containing "coffee"

  Scenario: Search on empty project
    Given I own an empty project
    And I visit my project's home page
    When I search for term "coffee"
    Then I should see empty result
