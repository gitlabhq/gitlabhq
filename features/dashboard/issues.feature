Feature: Dashboard Issues
  Background:
    Given I sign in as a user
    And I have authored issues
    And I have assigned issues
    And I have other issues
    And I visit dashboard issues page

  Scenario: I should see assigned issues
    Then I should see issues assigned to me

  Scenario: I should see authored issues
    When I click "Authored by me" link
    Then I should see issues authored by me

  Scenario: I should see all issues
    When I click "All" link
    Then I should see all issues
