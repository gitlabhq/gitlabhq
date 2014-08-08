@admin
Feature: Admin email
  Background:
    Given I sign in as an admin
    And I visit admin email page

  Scenario: See email page
    Then I see all previous email notifications

  Scenario: Create a new email notification
    When I click new email notification
    And submit form with email notification info
    Then I should be redirected to the email notification page
    And I should see newly created email notification

  Scenario: Adding recipients for email notification
    Given email notification 'maintenance'
    And I visit email notification 'maintenance'
    When I submit recipients
    Then I should see the reciepints

  Scenario: Sending email notification
    Given email notification 'maintenance' with selected recipients
    And I visit email notification 'maintenance'
    When I click send
    Then I should see the notification has been sent
