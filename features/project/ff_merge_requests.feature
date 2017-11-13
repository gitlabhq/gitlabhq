Feature: Project Ff Merge Requests
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" have "Bug NS-05" open merge request with diffs inside
    And merge request "Bug NS-05" is mergeable

  @javascript
  Scenario: I do ff-only merge for rebased branch
    Given ff merge enabled
    And merge request "Bug NS-05" is rebased
    When I visit merge request page "Bug NS-05"
    Then I should see ff-only merge button
    When I accept this merge request
    Then I should see merged request

  @javascript
  Scenario: I do ff-only merge for merged branch
    Given ff merge enabled
    And merge request "Bug NS-05" merged target
    When I visit merge request page "Bug NS-05"
    Then I should see ff-only merge button
    When I accept this merge request
    Then I should see merged request
