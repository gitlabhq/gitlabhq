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
  Scenario: I should switch "branch" and "tag"
    When I switch ref to "stable"
    Then page should select "stable" in select box
    And page should have "stable" on graph
    When I switch ref to "v2.1.0"
    Then page should select "v2.1.0" in select box
    And page should have "v2.1.0" on graph

  @javascript
  Scenario: I should looking for a commit by SHA
    When I looking for a commit by SHA of "v2.1.0"
    Then page should have network graph
    And page should select "master" in select box
    And page should have "v2.1.0" on graph

  @javascript
  Scenario: I should filter selected tag
    When I switch ref to "v2.1.0"
    Then page should have content not containing "v2.1.0"
    When click "Show only selected branch" checkbox
    Then page should not have content not containing "v2.1.0"
    When click "Show only selected branch" checkbox
    Then page should have content not containing "v2.1.0"

  Scenario: I should fail to look for a commit
    When I look for a commit by ";"
    Then page status code should be 404
