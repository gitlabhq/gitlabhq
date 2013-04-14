Feature: Project Search code
  Background:
    Given I sign in as a user
    And I own project "Shop"
    Given I visit project source page

  Scenario: Search for term "Welcome to Gitlab"
    When I search for term "Welcome to Gitlab"
    Then I should see files from repository containing "Welcome to Gitlab" 
