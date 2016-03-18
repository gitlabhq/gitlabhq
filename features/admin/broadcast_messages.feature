@admin
Feature: Admin Broadcast Messages
  Background:
    Given I sign in as an admin
    And application already has a broadcast message
    And I visit admin messages page

  Scenario: See broadcast messages list
    Then I should see all broadcast messages

  Scenario: Create a customized broadcast message
    When submit form with new customized broadcast message
    Then I should be redirected to admin messages page
    And I should see newly created broadcast message
    Then I visit dashboard page
    And I should see a customized broadcast message

  Scenario: Edit an existing broadcast message
    When I edit an existing broadcast message
    And I change the broadcast message text
    Then I should be redirected to admin messages page
    And I should see the updated broadcast message

  Scenario: Remove an existing broadcast message
    When I remove an existing broadcast message
    Then I should be redirected to admin messages page
    And I should not see the removed broadcast message

  @javascript
  Scenario: Live preview a customized broadcast message
    When I visit admin messages page
    And I enter a broadcast message with Markdown
    Then I should see a live preview of the rendered broadcast message
