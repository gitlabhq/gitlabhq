@labels
Feature: Labels
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has labels: "bug", "feature", "enhancement"
    When I visit project "Shop" labels page

  @javascript
  Scenario: I can subscribe to a label
    Then I should see that I am not subscribed to the "bug" label
    When I click button "Subscribe" for the "bug" label
    Then I should see that I am subscribed to the "bug" label
    When I click button "Unsubscribe" for the "bug" label
    Then I should see that I am not subscribed to the "bug" label
