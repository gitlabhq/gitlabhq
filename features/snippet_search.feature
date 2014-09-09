@dashboard
Feature: Snippet Search
  Background:
    Given I sign in as a user
    And I have public "Personal snippet one" snippet
    And I have private "Personal snippet private" snippet
    And I have a public many lined snippet

  Scenario: I should see my public and private snippets
    When I search for "snippet" in snippet titles
    Then I should see "Personal snippet one" in results
    And I should see "Personal snippet private" in results

  Scenario: I should see three surrounding lines on either side of a matching snippet line
    When I search for "line seven" in snippet contents
    Then I should see "line four" in results
    And I should see "line seven" in results
    And I should see "line ten" in results
    And I should not see "line three" in results
    And I should not see "line eleven" in results
