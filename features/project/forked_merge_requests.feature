Feature: Project Forked Merge Requests
  Background:
    Given I sign in as a user
    And I am a member of project "Shop"
    And I have a project forked off of "Shop" called "Forked Shop"


  @javascript
  Scenario: I can visit the target projects commit for a forked merge request
    Given I visit project "Forked Shop" merge requests page
    And I click link "New Merge Request"
    And I fill out a "Forked Wiki Feature" merge request
    And I follow the target commit link
    Then I should see the commit under the forked from project

  @javascript
  Scenario: I submit new unassigned merge request to a forked project
    Given I visit project "Forked Shop" merge requests page
    And I click link "New Merge Request"
    And I fill out a "Forked Wiki Feature" merge request
    And I submit the merge request
    Then I should see merge request "Forked Wiki Feature"


  @javascript
  Scenario: I should see last push widget
    Given project "Forked Shop" has push event
    And I visit dashboard page
    Then I should see last push widget
    And I click "Create Merge Request on fork" link
    Then I see prefilled new Merge Request page for the forked project


