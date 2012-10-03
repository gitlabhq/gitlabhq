Feature: Groups
  Background:
    Given I sign in as a user
    And I have group with projects

  Scenario: I should see group dashboard list
    When I visit group page
    Then I should see projects list
    And I should see projects activity feed
