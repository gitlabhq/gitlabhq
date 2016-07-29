Feature: Group Analytics
  Background:
    Given I sign in as "John Doe"
    And "John Doe" is owner of group "Owned"

  Scenario: I should see group "Owned" analytics page
    When I visit group "Owned" page
    And I click on group analytics
    Then I should see group analytics page
