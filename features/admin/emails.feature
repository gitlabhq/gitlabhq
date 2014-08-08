@admin
Feature: Admin email
  Background:
    Given I sign in as an admin
    And I visit admin email page

  Scenario: Create a new email notification
    When I click new email notification
    And submit form with email notification info
    Then I should see a notification email is begin send
