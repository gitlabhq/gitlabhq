Feature: Project Graph
  Background:
    Given I sign in as a user
    And I own project "Shop"

  @javascript
  Scenario: I should see project graphs
    When I visit project "Shop" graph page
    Then page should have graphs

  @javascript
  Scenario: I should see project commits graphs
    When I visit project "Shop" commits graph page
    Then page should have commits graphs
