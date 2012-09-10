Feature: Project Wiki
  Background:
    Given I sign in as a user
    And I own project "Shop"
    Given I visit project wiki page

  Scenario: Add new page
    Given I create Wiki page
    Then I should see newly created wiki page

  @javascript
  Scenario: I comment wiki page
    Given I create Wiki page
    And I leave a comment like "XML attached"
    Then I should see comment "XML attached"
