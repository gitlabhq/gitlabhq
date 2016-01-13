@project_issues
Feature: Project Issues Referenced Merge Requests
  Background:
    Given I sign in as "John Doe"
    And "John Doe" owns public project "Community"
    And project "Community" has "Public Issue 01" open issue
    And I logout
    And I sign in as "Mary Jane"
    And "Mary Jane" owns private project "Private Library"
    And project "Private Library" has "Fix NS-01" open merge request
    And I visit merge request page "Fix NS-01"
    And I leave a comment referencing issue "Public Issue 01" from project "Private Library"
    And I logout

  @javascript
  Scenario: Viewing the public issue as a "John Doe"
    Given I sign in as "John Doe"
    When I visit issue page "Public Issue 01"
    Then I should not see any related merge requests

  @javascript
  Scenario: Viewing the public issue as "Mary Jane"
    Given I sign in as "Mary Jane"
    When I visit issue page "Public Issue 01"
    Then I should see the "Fix NS-01" related merge request
