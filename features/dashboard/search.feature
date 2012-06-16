Feature: Dashboard Search
  Background: 
    Given I signin as a user
    And I own project "Shop"
    And I visit dashboard search page 

  Scenario: I should see project i'm looking for
    Given I search for "Sho"
    Then I should see "Shop" project link


