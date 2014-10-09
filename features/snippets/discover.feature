@snippets
Feature: Snippets Discover
  Background:
    Given I sign in as a user
    And I have public "Personal snippet one" snippet
    And I have private "Personal snippet private" snippet
    And I have internal "Personal snippet internal" snippet

  Scenario: I should see snippets
    Given I visit snippets page
    Then I should see "Personal snippet one" in snippets
    And I should see "Personal snippet internal" in snippets
    And I should not see "Personal snippet private" in snippets
