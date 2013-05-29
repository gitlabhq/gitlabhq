Feature: Project Search code
  Background:
    Given I sign in as a user
    And I own project "Shop"
    Given I visit project source page

  Scenario: Search for term "Welcome to GitLab"
    When I search for term "Welcome to GitLab"
    Then I should see files from repository containing "Welcome to GitLab" 
