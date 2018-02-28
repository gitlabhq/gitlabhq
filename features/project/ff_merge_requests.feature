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

  @javascript
  Scenario: I do rebase before ff-only merge
    Given ff merge enabled
    And rebase before merge enabled
    When I visit merge request page "Bug NS-05"
    Then I should see rebase button
    When I press rebase button
    Then I should see rebase in progress message

  @javascript
  Scenario: I do rebase before regular merge
    Given rebase before merge enabled
    When I visit merge request page "Bug NS-05"
    Then I should see rebase button
    When I press rebase button
    Then I should see rebase in progress message
