@dashboard
Feature: Dashboard Search
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And I visit dashboard search page

  Scenario: I should see project I am looking for
    Given I search for "Sho"
    Then I should see "Shop" project link
