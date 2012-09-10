Feature: Project Wall
  In order to use Project Wall
  A user should be able to read and write messages

  Background:
    Given I sign in as a user
    And I own project "Shop"
    And I visit project "Shop" wall page

  @javascript
  Scenario: Write comment
    Given I write new comment "my special test message"
    Then I should see project wall note "my special test message"

    Then I visit project "Shop" wall page
    And I should see project wall note "my special test message"
