@admin
Feature: Admin push rules sample
  Background:
    Given I sign in as an admin
    And I visit push rules page

  Scenario: I can create push rule sample
    When I fill in a form and submit
    Then I see my push rule saved
