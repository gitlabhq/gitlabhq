Feature: Public Projects
  Background:
    Given I sign in as a user

  Scenario: I should see the list of public projects
    When I visit the public projects area
    Then I should see the list of public projects

