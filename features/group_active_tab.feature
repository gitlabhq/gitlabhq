Feature: Group Active Tab
  Background:
    Given I sign in as "John Doe"
    And "John Doe" is owner of group "Owned"
    When I visit group "Owned" settings page

  Scenario: On Audit events
    When I go to "Audit Events"
    Then the active sub nav should be Audit Events
    And no other sub navs should be active
    And the active main tab should be Settings

  Scenario: On Web Hooks
    When I go to "Web Hooks"
    Then the active sub nav should be Web Hooks
    And no other sub navs should be active
    And the active main tab should be Settings

