Feature: Admin email
  Background:
    Given I sign in as an admin
    And there are groups with projects

  @javascript
  Scenario: Create a new email notification
    Given I visit admin email page
    When I submit form with email notification info
    Then I should see a notification email is begin sent
    And admin emails are being sent

  Scenario: Create a new email notification
    Given I visit unsubscribe from admin notification page
    When I click unsubscribe
    Then I get redirected to the sign in path
    And unsubscribed email is sent
