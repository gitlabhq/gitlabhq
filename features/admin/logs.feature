@admin
Feature: Admin Logs
  Background:
    Given I sign in as an admin

  Scenario: On Admin Logs
    Given I visit admin logs page
    Then I should see tabs with available logs
