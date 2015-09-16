Feature: Admin Issues Labels
  Background:
    Given I sign in as an admin
    And I have labels: "bug", "feature", "enhancement"
    Given I visit admin labels page

  Scenario: I should see labels list
    Then I should see label 'bug'
    And I should see label 'feature'

  Scenario: I create new label
    Given I submit new label 'support'
    Then I should see label 'support'

  Scenario: I edit label
    Given I visit 'bug' label edit page
    When I change label 'bug' to 'fix'
    Then I should not see label 'bug'
    Then I should see label 'fix'

  Scenario: I remove label
    When I remove label 'bug'
    Then I should not see label 'bug'

  @javascript
  Scenario: I delete all labels
    When I delete all labels
    Then I should see labels help message

  Scenario: I create a label with invalid color
    Given I visit admin new label page
    When I submit new label with invalid color
    Then I should see label color error message

  Scenario: I create a label that already exists
    Given I visit admin new label page
    When I submit new label 'bug'
    Then I should see label exist error message
