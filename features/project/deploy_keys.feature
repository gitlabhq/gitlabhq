Feature: Project Deploy Keys
  Background:
    Given I sign in as a user
    And I own project "Shop"

  Scenario: I should see deploy keys list
    Given project has deploy key
    When I visit project deploy keys page
    Then I should see project deploy keys

  Scenario: I add new deploy key
    Given I visit project deploy keys page
    When I click 'New Deploy Key'
    And I submit new deploy key
    Then I should be on deploy keys page
    And I should see newly created deploy key

  Scenario: I attach deploy key to project
    Given other project has deploy key
    And I visit project deploy keys page
    When I click attach deploy key
    Then I should be on deploy keys page
    And I should see newly created deploy key
