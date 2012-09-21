Feature: Project Labels
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" have issues tags: "bug", "feature"
    Given I visit project "Shop" labels page

  Scenario: I should see active milestones
    Then I should see label "bug"
    And I should see label "feature"
