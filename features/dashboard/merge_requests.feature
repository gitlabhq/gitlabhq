Feature: Dashboard Merge Requests
  Background:
    Given I sign in as a user
    And I have authored merge requests
    And I have assigned merge requests
    And I have other merge requests
    And I visit dashboard merge requests page

  Scenario: I should see assigned merge_requests
    Then I should see merge requests assigned to me

  Scenario: I should see authored merge_requests
    When I click "Authored by me" link
    Then I should see merge requests authored by me

  Scenario: I should see all merge_requests
    When I click "All" link
    Then I should see all merge requests
