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

  