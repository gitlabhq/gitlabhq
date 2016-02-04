Feature: Admin spam logs
  Background:
    Given I sign in as an admin
    And spam logs exist

  Scenario: Browse spam logs
    When I visit spam logs page
    Then I should see list of spam logs
