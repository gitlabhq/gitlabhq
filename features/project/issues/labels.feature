Feature: Project Labels
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has labels: "bug", "feature", "enhancement"
    Given I visit project "Shop" labels page

  Scenario: I should see labels list
    Then I should see label "bug"
    And I should see label "feature"

  Scenario: I create new label
    Given I visit new label page
    When I submit new label 'support'
    Then I should see label 'support'

  Scenario: I edit label
    Given I visit 'bug' label edit page
    When I change label 'bug' to 'fix'
    Then I should not see label 'bug'
    Then I should see label 'fix'

  Scenario: I remove label
    When I remove label 'bug'
    Then I should not see label 'bug'
