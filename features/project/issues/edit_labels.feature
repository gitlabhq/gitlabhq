Feature: Project Edit Labels
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has labels: "bug", "feature", "enhancement"
    And project "Shop" has issue "Bugfix1" with labels: "bug", "feature"
    Given I visit project "Shop" issues page
    Given I visit issue "Bugfix1" show page

  Scenario: I should see issue labels
    Then I should see "bug" in labels list
    And I should see "feature" in labels list
    And I should not see "enhancement" in labels list

  @javascript
  Scenario: I add one label
    Given I select "enhancement" from select issue labels
    Then I should see "enhancement" in labels list

  @javascript
  Scenario: I remove one label
    Given I click on "bug" remove link
    Then I should not see "bug" in labels list
    And I should see "bug" in select issue labels
