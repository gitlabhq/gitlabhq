@admin
Feature: Admin email
  Background:
    Given I sign in as an admin
    And there are groups with projects

  Scenario: Create a new email notification
    Given I visit admin email page
    When I submit form with email notification info
    Then I should see a notification email is begin send
    And admin emails are being sent
