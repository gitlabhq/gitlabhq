@dashboard
Feature: Dashboard Todos
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And "John Doe" is a developer of project "Shop"
    And "Mary Jane" is a developer of project "Shop"
    And "Mary Jane" owns private project "Enterprise"
    And I am a developer of project "Enterprise"
    And I have todos
    And I visit dashboard todos page

  @javascript
  Scenario: I mark todos as done
    Then I should see todos assigned to me
    And I mark the todo as done
    Then I should see the todo marked as done

  @javascript
  Scenario: I mark all todos as done
    Then I should see todos assigned to me
    And I mark all todos as done
    Then I should see all todos marked as done

  @javascript
    Scenario: I click on a todo row
      Given I click on the todo
      Then I should be directed to the corresponding page
