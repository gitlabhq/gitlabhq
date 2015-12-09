@project_issues
Feature: Project Issues Filter Labels
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has labels: "bug", "feature", "enhancement"
    And project "Shop" has issue "Bugfix1" with labels: "bug", "feature"
    And project "Shop" has issue "Bugfix2" with labels: "bug", "enhancement"
    And project "Shop" has issue "Feature1" with labels: "feature"
    Given I visit project "Shop" issues page

  @javascript
  Scenario: I filter by one label
    Given I click link "bug"
    Then I should see "Bugfix1" in issues list
    And I should see "Bugfix2" in issues list
    And I should not see "Feature1" in issues list

  # TODO: make labels filter works according to this scanario
  # right now it looks for label 1 OR label 2. Old behaviour (this test) was
  # all issues that have both label 1 AND label 2
  #Scenario: I filter by two labels
    #Given I click link "bug"
    #And I click link "feature"
    #Then I should see "Bugfix1" in issues list
    #And I should not see "Bugfix2" in issues list
    #And I should not see "Feature1" in issues list
