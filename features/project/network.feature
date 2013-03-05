Feature: Project Network Graph
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And I visit project "Shop" network page

  @javascript
  Scenario: I should see project network
    Then page should have network graph
    And page should select "master" in select box
    And page should have "master" on graph

  @javascript
  Scenario: I should switch ref to "stable"
    When I switch ref to "stable"
    Then page should have network graph
    And page should select "stable" in select box
    And page should have "stable" on graph

  @javascript
  Scenario: I should looking for a commit by SHA of "v2.1.0"
    When I looking for a commit by SHA of "v2.1.0"
    Then page should have network graph
    And page should select "master" in select box
    And page should have "v2.1.0" on graph
