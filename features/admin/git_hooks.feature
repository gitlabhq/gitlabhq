@admin
Feature: Admin git hooks sample
  Background:
    Given I sign in as an admin
    And I visit git hooks page

  Scenario: I can create git hook sample
    When I fill in a form and submit
    Then I see my git hook saved