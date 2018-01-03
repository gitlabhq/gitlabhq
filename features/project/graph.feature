Feature: Project Graph
  Background:
    Given I sign in as a user
    And I own project "Shop"

  @javascript
  Scenario: I should see project graphs
    When I visit project "Shop" graph page
    Then page should have graphs

  @javascript
  Scenario: I should see project languages & commits graphs on commits graph url
    When I visit project "Shop" commits graph page
    Then page should have commits graphs
    Then page should have languages graphs

  @javascript
  Scenario: I should see project ci graphs
    Given project "Shop" has CI enabled
    When I visit project "Shop" CI graph page
    Then page should have CI graphs

  @javascript
  Scenario: I should see project languages & commits graphs on language graph url
    When I visit project "Shop" languages graph page
    Then page should have languages graphs
    Then page should have commits graphs

  @javascript
  Scenario: I should see project languages & commits graphs on charts url
    When I visit project "Shop" chart page
    Then page should have languages graphs
    Then page should have commits graphs
