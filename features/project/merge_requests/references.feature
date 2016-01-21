@project_merge_requests
Feature: Project Merge Requests References
  Background:
    Given I sign in as "John Doe"
    And public project "Community"
    And "John Doe" owns public project "Community"
    And project "Community" has "Community fix" open merge request
    And I logout
    And I sign in as "Mary Jane"
    And private project "Enterprise"
    And "Mary Jane" owns private project "Enterprise"
    And project "Enterprise" has "Enterprise issue" open issue
    And project "Enterprise" has "Enterprise fix" open merge request
    And I visit issue page "Enterprise issue"
    And I leave a comment referencing issue "Community fix"
    And I visit merge request page "Enterprise fix"
    And I leave a comment referencing issue "Community fix"
    And I logout

  @javascript
  Scenario: Viewing the public issue as a "John Doe"
    Given I sign in as "John Doe"
    When I visit issue page "Community fix"
    Then I should see no notes at all

  @javascript
  Scenario: Viewing the public issue as "Mary Jane"
    Given I sign in as "Mary Jane"
    When I visit issue page "Community fix"
    And I should see a note linking to "Enterprise fix" merge request
    And I should see a note linking to "Enterprise issue" issue
