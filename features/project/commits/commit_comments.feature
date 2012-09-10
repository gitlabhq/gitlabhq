Feature: Project Comment commit
  Background:
    Given I sign in as a user
    And I own project "Shop"
    Given I visit project commit page

  @javascript
  Scenario: I comment commit
    Given I leave a comment like "XML attached"
    Then I should see comment "XML attached"
