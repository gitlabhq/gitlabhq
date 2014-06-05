@snippets
Feature: User Snippets
  Background:
    Given I sign in as a user
    And I have public "Personal snippet one" snippet
    And I have private "Personal snippet private" snippet

  Scenario: I should see all my snippets
    Given I visit my snippets page
    Then I should see "Personal snippet one" in snippets
    And I should see "Personal snippet private" in snippets

  Scenario: I can see only my private snippets
    Given I visit my snippets page
    And I click "Private" filter
    Then I should not see "Personal snippet one" in snippets
    And I should see "Personal snippet private" in snippets

  Scenario: I can see only my public snippets
    Given I visit my snippets page
    And I click "Public" filter
    Then I should see "Personal snippet one" in snippets
    And I should not see "Personal snippet private" in snippets
