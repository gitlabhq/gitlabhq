@snippets
Feature: Discover Snippets
  Background:
    Given I sign in as a user
    And I have public "Personal snippet one" snippet
    And I have private "Personal snippet private" snippet

  Scenario: I should see snippets
    Given I visit snippets page
    Then I should see "Personal snippet one" in snippets
    And I should not see "Personal snippet private" in snippets
