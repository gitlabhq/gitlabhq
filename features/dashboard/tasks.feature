@dashboard
Feature: Dashboard Tasks
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And "John Doe" is a developer of project "Shop"
    And "Mary Jane" is a developer of project "Shop"
    And "Mary Jane" owns private project "Enterprise"
    And I am a developer of project "Enterprise"
    And I have pending tasks
    And I visit dashboard task queue page

  @javascript
  Scenario: I mark pending tasks as done
    Then I should see pending tasks assigned to me
    And I mark the pending task as done
    And I click on the "Done" tab
    Then I should see all tasks marked as done

  @javascript
    Scenario: I filter by project
      Given I filter by "Enterprise"
      Then I should not see tasks

  @javascript
    Scenario: I filter by author
      Given I filter by "John Doe"
      Then I should not see tasks related to "Mary Jane" in the list

  @javascript
    Scenario: I filter by type
      Given I filter by "Issue"
      Then I should not see tasks related to "Merge Requests" in the list

  @javascript
    Scenario: I filter by action
      Given I filter by "Mentioned"
      Then I should not see tasks related to "Assignments" in the list
