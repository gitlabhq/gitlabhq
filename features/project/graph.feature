Feature: Project Graph
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And I visit project "Shop" graph page

  @javascript
  Scenario: I should see project graphs
    Then page should have graphs
