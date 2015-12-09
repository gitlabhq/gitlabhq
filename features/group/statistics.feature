Feature: Group Statistics
  Background:
    Given I sign in as "John Doe"
    And "John Doe" is owner of group "Owned"

  Scenario: I should see group "Owned" statistics page
    When I visit group "Owned" page
    And I click on group statistics
    Then I should see group statistics page
