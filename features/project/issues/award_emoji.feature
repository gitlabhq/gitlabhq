@project_issues
Feature: Award Emoji
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" has issue "Bugfix"
    And I visit "Bugfix" issue page

  @javascript
  Scenario: I repeatedly add and remove thumbsup award in the issue
    Given I click the thumbsup award Emoji
    Then I have award added
    Given I click the thumbsup award Emoji
    Then I have no awards added
    Given I click the thumbsup award Emoji
    Then I have award added

  @javascript
  Scenario: I add and remove custom award in the issue
    Given I click to emoji-picker
    Then The search field is focused
    And I click to emoji in the picker
    Then I have award added
    And I can remove it by clicking to icon

  @javascript
  Scenario: I can see the list of emoji categories
    Given I click to emoji-picker
    Then The search field is focused
    Then I can see the activity and food categories

  @javascript
  Scenario: I can search emoji
    Given I click to emoji-picker
    Then The search field is focused
    And I search "hand"
    Then I see search result for "hand"

  @javascript
  Scenario: I add award emoji using regular comment
    Given I leave comment with a single emoji
    Then I have award added
