Feature: Admin Broadcast Messages
  Background:
    Given I sign in as an admin
    And application already has admin messages
    And I visit admin messages page

  Scenario: See broadcast messages list
    Then I should be all broadcast messages

  Scenario: Create a broadcast message
    When submit form with new broadcast message
    Then I should be redirected to admin messages page
    And I should see newly created broadcast message
