Feature: Wiki
  Background: 
    Given I signin as a user
    And I own project "Shop"
    Given I visit project wiki page

  Scenario: Add new page
    Given I create Wiki page
    Then I should see newly created wiki page
