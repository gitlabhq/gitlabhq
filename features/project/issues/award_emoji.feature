@project_issues
Feature: Award Emoji
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has issue "Bugfix"
    And I visit "Bugfix" issue page

  @javascript
  Scenario: I add and remove award in the issue
    Given I click to emoji-picker
    And I click to emoji in the picker
    Then I have award added
    And I can remove it by clicking to icon

  @javascript
  Scenario: I add award emoji using regular comment
  Given I leave comment with a single emoji
  Then I have award added
