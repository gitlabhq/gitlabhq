@javascript
Feature: Project Wall
  In order to use Project Wall
  A user
  Should be able to read & write messages

  Background:
    Given I signin as a user
    And I own project "Shop"
    And I visit project "Shop" wall page 

  Scenario: Write comment
    Given I write new comment "my special test message"
    Then I should see project wall note "my special test message"

    Then I visit project "Shop" wall page 
    And I should see project wall note "my special test message"
