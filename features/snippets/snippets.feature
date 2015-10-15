@snippets
Feature: Snippets
  Background:
    Given I sign in as a user
    And I have public "Personal snippet one" snippet
    And I have private "Personal snippet private" snippet

  Scenario: I create new snippet
    Given I visit new snippet page
    And I submit new snippet "Personal snippet three"
    Then I should see snippet "Personal snippet three"

  Scenario: I update "Personal snippet one"
    Given I visit snippet page "Personal snippet one"
    And I click link "Edit"
    And I submit new title "Personal snippet new title"
    Then I should see "Personal snippet new title"

  Scenario: Set "Personal snippet one" public
    Given I visit snippet page "Personal snippet one"
    And I click link "Edit"
    And I uncheck "Private" checkbox
    Then I should see "Personal snippet one" public

  Scenario: I destroy "Personal snippet one"
    Given I visit snippet page "Personal snippet one"
    And I click link "Delete"
    Then I should not see "Personal snippet one" in snippets

  Scenario: I create new internal snippet
    Given I logout directly
    And I sign in as an admin
    Then I visit new snippet page
    And I submit new internal snippet
    Then I visit snippet page "Internal personal snippet one"
    And I logout directly
    Then I sign in as a user
    Given I visit new snippet page
    Then I visit snippet page "Internal personal snippet one"
