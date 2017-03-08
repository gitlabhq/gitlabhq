Feature: Push Rules
  Background:
    Given I sign in as a user
    And I own project "Shop"

  Scenario: I should see push rule form
    When I visit project push rules page
    Then I should see push rule form
