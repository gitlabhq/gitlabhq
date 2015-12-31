Feature: Project Ff Merge Requests
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" have "Bug NS-05" open merge request with diffs inside
    And ff merge enabled
    And merge request "Bug NS-05" is mergeable

  Scenario: I do ff-only merge
    Given merge request "Bug NS-05" is rebased
    When I visit merge request page "Bug NS-05"
    Then I should see ff-only merge button

  @javascript
  Scenario: I do rebase before ff-only merge
    Given rebase before merge enabled
    When I visit merge request page "Bug NS-05"
    Then I should see rebase button
    When I press rebase button
    Then I should see rebase in progress message

  Scenario: I should do rebase before ff-only merge
    When I visit merge request page "Bug NS-05"
    Then I should not see rebase button
    And I should see rebase message
