Feature: Snippets Search
  Background:
    Given I sign in as a user
    And Elasticsearch is enabled

  Scenario: I search through the snippets
    Given there is a snippet "index" with "php rocks" string
    And there is a snippet "php" with "benefits" string
    And I visit snippets page
    Then I search "php"
    And I find "index" snippet
    Then I select search by titles and filenames
    And I find "php" snippet