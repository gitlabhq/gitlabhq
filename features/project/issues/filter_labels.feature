Feature: Project Filter Labels
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has issue "Bugfix1" with tags: "bug", "feature"
    And project "Shop" has issue "Bugfix2" with tags: "bug", "enhancement"
    And project "Shop" has issue "Feature1" with tags: "feature"
    Given I visit project "Shop" issues page

  Scenario: I should see project issues
    Then I should see "bug" in labels filter
    And I should see "feature" in labels filter
    And I should see "enhancement" in labels filter

  Scenario: I filter by one label
    Given I click link "bug"
    Then I should see "Bugfix1" in issues list
    And I should see "Bugfix2" in issues list
    And I should not see "Feature1" in issues list

  Scenario: I filter by two labels
    Given I click link "bug"
    And I click link "feature"
    Then I should see "Bugfix1" in issues list
    And I should not see "Bugfix2" in issues list
    And I should not see "Feature1" in issues list
