Feature: Public Snippets Feature
  Background:
    Given world public snippet "World Public Snippet"
    And gitlab public snippet "Gitlab Public Snippet"
    And private snippet "Private Snippet"

  Scenario: I visit public snippets area
    When I visit the public snippets area
    Then I should see snippet "World Public Snippet"
    And I should not see snippet "Gitlab Public Snippet"
    And I should not see snippet "Private Snippet"

  Scenario: I visit public snippet page
    When I visit public page for "World Public Snippet" snippet
    Then I should see snippet "World Public Snippet"
