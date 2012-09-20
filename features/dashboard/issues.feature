Feature: Dashboard Issues
  Background:
    Given I sign in as a user
    And I have assigned issues
    And I visit dashboard issues page

  Scenario: I should see issues list
    Then I should see issues assigned to me
