Feature: Audit Event
  Background:
    Given I sign in as a user
    And I own project "Shop"

  Scenario: I add new deploy key
    Given I created new depoloy key
    When I visit audit event page
    Then I see deploy key event
    When I remove deploy key
    And I visit audit event page
    Then I see remove deploy key event

  @javascript
  Scenario: I should see audit events
    And gitlab user "Pete"
    And "Pete" is "Shop" developer
    When I visit project "Shop" page
    And I go to "Members"
    And I change "Pete" access level to master
    And I visit project "Shop" settings page
    And I go to "Audit Events"
    Then I should see the audit event listed
