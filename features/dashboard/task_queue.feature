@dashboard
Feature: Dashboard Task Queue
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And "John Doe" is a developer of project "Shop"
    And I have pending tasks
    And I visit dashboard task queue page

  @javascript
  Scenario: I mark pending tasks as done
    Then I should see pending tasks assigned to me
    And I mark the pending task as done
    And I click on the "Done" tab
    Then I should see all tasks marked as done
