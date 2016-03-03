Feature: Project Milestone
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has labels: "bug", "feature", "enhancement"
    And project "Shop" has milestone "v2.2"
    And milestone has issue "Bugfix1" with labels: "bug", "feature"
    And milestone has issue "Bugfix2" with labels: "bug", "enhancement"


  @javascript
  Scenario: Listing issues from issues tab
    Given I visit project "Shop" milestones page
    And I click link "v2.2"
    Then I should see the labels "bug", "enhancement" and "feature"
    And I should see the "bug" label listed only once

  @javascript
  Scenario: Listing labels from labels tab
    Given I visit project "Shop" milestones page
    And I click link "v2.2"
    And I click link "Labels"
    Then I should see the list of labels
    And I should see the labels "bug", "enhancement" and "feature"
