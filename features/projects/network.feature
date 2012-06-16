@javascript
Feature: Project Network Graph

  Background:
    Given I signin as a user
    And I own project "Shop"
    And I visit project "Shop" network page 

  Scenario: I should see project network
    Then page should have network graph
    

