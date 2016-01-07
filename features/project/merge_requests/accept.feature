@project_merge_requests
Feature: Project Merge Requests Acceptance
  Background:
    Given There is an open Merge Request
      And I am signed in as a developer of the project

  @javascript
  Scenario: Accepting the Merge Request and removing the source branch
    Given I am on the Merge Request detail page
    When I click on "Remove source branch" option
    And I click on Accept Merge Request
    Then I should see merge request merged
    And I should not see the Remove Source Branch button

  @javascript
  Scenario: Accepting the Merge Request when URL has an anchor
    Given I am on the Merge Request detail with note anchor page
    When I click on "Remove source branch" option
    And I click on Accept Merge Request
    Then I should see merge request merged
    And I should not see the Remove Source Branch button

  @javascript
  Scenario: Accepting the Merge Request without removing the source branch
    Given I am on the Merge Request detail page
    When I click on Accept Merge Request
    Then I should see merge request merged
    And I should see the Remove Source Branch button
