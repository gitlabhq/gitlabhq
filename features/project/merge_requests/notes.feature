@project_merge_requests
Feature: Project Merge Requests Notes
  Background:
    Given I sign in as "Mary Jane"
    And I own public project "Public Shop"
    And project "Public Shop" has "Public Issue 01" open issue
    And I logout
    And I sign in as "John Doe"
    And I own private project "Private Library"
    And project "Private Library" has "Private MR 01" open merge request
    And I visit merge request page "Private MR 01"
    And I leave a comment with link to issue "Public Issue 01"
    And I logout

  @javascript
  Scenario: Viewing the public issue as a lambda user
    Given I sign in as "Mary Jane"
    When I visit issue page "Public Issue 01"
    Then I should not see any related merge requests

  @javascript
  Scenario: Viewing the public issue as "John Doe"
    Given I sign in as "John Doe"
    When I visit issue page "Public Issue 01"
    Then I should see the "Private MR 01" related merge request
