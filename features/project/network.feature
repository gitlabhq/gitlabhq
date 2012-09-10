Feature: Project Network Graph
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And I visit project "Shop" network page

  @javascript
  Scenario: I should see project network
    Then page should have network graph
