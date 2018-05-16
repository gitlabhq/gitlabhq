Feature: Project Deploy Keys
  Background:
    Given I sign in as a user
    And I own project "Shop"

  @javascript
  Scenario: I should see deploy keys list
    Given project has deploy key
    When I visit project deploy keys page
    Then I should see project deploy key

  @javascript
  Scenario: I should see project deploy keys
    Given other projects have deploy keys
    When I visit project deploy keys page
    Then I should see other project deploy key
    And I should only see the same deploy key once

  @javascript
  Scenario: I should see public deploy keys
    Given public deploy key exists
    When I visit project deploy keys page
    Then I should see public deploy key

  @javascript
  Scenario: I add new deploy key
    Given I visit project deploy keys page
    And I submit new deploy key
    Then I should be on deploy keys page
    And I should see newly created deploy key

  @javascript
  Scenario: I attach other project deploy key to project
    Given other projects have deploy keys
    And I visit project deploy keys page
    When I click attach deploy key
    Then I should be on deploy keys page
    And I should see newly created deploy key

  @javascript
  Scenario: I attach public deploy key to project
    Given public deploy key exists
    And I visit project deploy keys page
    When I click attach deploy key
    Then I should be on deploy keys page
    And I should see newly created deploy key
