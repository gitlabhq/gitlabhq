Feature: Project Forked Merge Requests
  Background:
    Given I sign in as a user
    And I am a member of project "Shop"
    And I have a project forked off of "Shop" called "Forked Shop"

  Scenario: I submit new unassigned merge request to a forked project
    Given I visit project "Forked Shop" merge requests page
    And I click link "New Merge Request"
    And I fill out a "Merge Request On Forked Project" merge request
    And I submit the merge request
    Then I should see merge request "Merge Request On Forked Project"

  @javascript
  Scenario: I can edit a forked merge request
    Given I visit project "Forked Shop" merge requests page
    And I click link "New Merge Request"
    And I fill out a "Merge Request On Forked Project" merge request
    And I submit the merge request
    And I should see merge request "Merge Request On Forked Project"
    And I click link edit "Merge Request On Forked Project"
    Then I see the edit page prefilled for "Merge Request On Forked Project"
    And I update the merge request title
    And I save the merge request
    Then I should see the edited merge request

  @javascript
  Scenario: I cannot submit an invalid merge request
    Given I visit project "Forked Shop" merge requests page
    And I click link "New Merge Request"
    And I fill out an invalid "Merge Request On Forked Project" merge request
    Then I should see validation errors

  @javascript
  Scenario: Merge request should target fork repository by default
    Given I visit project "Forked Shop" merge requests page
    And I click link "New Merge Request"
    Then the target repository should be the original repository
