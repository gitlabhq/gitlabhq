Feature: Project Snippets
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" have "Snippet one" snippet
    And project "Shop" have no "Snippet two" snippet
    And I visit project "Shop" snippets page

  Scenario: I should see snippets
    Given I visit project "Shop" snippets page
    Then I should see "Snippet one" in snippets
    And I should not see "Snippet two" in snippets

  Scenario: I create new project snippet
    Given I click link "New Snippet"
    And I submit new snippet "Snippet three"
    Then I should see snippet "Snippet three"

  @javascript
  Scenario: I comment on a snippet "Snippet one"
    Given I visit snippet page "Snippet one"
    And I leave a comment like "Good snippet!"
    Then I should see comment "Good snippet!"

  Scenario: I update "Snippet one"
    Given I visit snippet page "Snippet one"
    And I click link "Edit"
    And I submit new title "Snippet new title"
    Then I should see "Snippet new title"

  Scenario: I destroy "Snippet one"
    Given I visit snippet page "Snippet one"
    And I click link "Remove Snippet"
    Then I should not see "Snippet one" in snippets
