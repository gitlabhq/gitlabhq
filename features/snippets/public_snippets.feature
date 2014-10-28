Feature: Public snippets
  Scenario: Unauthenticated user should see public snippets
    Given There is public "Personal snippet one" snippet
    And I visit snippet page "Personal snippet one"
    Then I should see snippet "Personal snippet one"

  Scenario: Unauthenticated user should see raw public snippets
    Given There is public "Personal snippet one" snippet
    And I visit snippet raw page "Personal snippet one"
    Then I should see raw snippet "Personal snippet one"
