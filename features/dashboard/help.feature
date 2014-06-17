@dashboard
Feature: Help
  Background:
    Given I sign in as a user
    And I visit the "Rake Tasks" help page

  Scenario: The markdown should be rendered correctly
    Then I should see "Rake Tasks" page markdown rendered
    And Header "Rebuild project satellites" should have correct ids and links
