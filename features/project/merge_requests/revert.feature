@project_merge_requests
Feature: Revert Merge Requests
  Background:
    Given There is an open Merge Request
      And I am signed in as a developer of the project
      And I am on the Merge Request detail page
      And I click on Accept Merge Request

  @javascript
  Scenario: I revert a merge request
    Given I click on the revert button
    And I revert the changes directly
    Then I should see the revert merge request notice

  @javascript
  Scenario: I revert a merge request that was previously reverted
    Given I click on the revert button
    And I revert the changes directly
    And I am on the Merge Request detail page
    And I click on the revert button
    And I revert the changes directly
    Then I should see a revert error

  @javascript
  Scenario: I revert a merge request in a new merge request
    Given I click on the revert button
    And I am on the Merge Request detail page
    And I click on the revert button
    And I revert the changes in a new merge request
    Then I should see the new merge request notice
