@labels
Feature: Labels
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And I visit project "Shop" issues page
    And project "Shop" has labels: "bug", "feature", "enhancement"

  @javascript
  Scenario: I can subscribe to a label
    When I visit project "Shop" labels page
    Then I should see that I am unsubscribed
    When I click button "Subscribe"
    Then I should see that I am subscribed
    When I click button "Unsubscribe"
    Then I should see that I am unsubscribed
