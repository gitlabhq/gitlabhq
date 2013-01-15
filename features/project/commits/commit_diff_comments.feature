Feature: Comments on commit diffs
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And I visit project commit page

  @javascript
  Scenario: I can access add diff comment buttons
    Then I should see add a diff comment button

  @javascript
  Scenario: I can comment on a commit diff
    Given I leave a diff comment like "Typo, please fix"
    Then I should see a diff comment saying "Typo, please fix"

  @javascript
  Scenario: I get a temporary form for the first comment on a diff line
    Given I open a diff comment form
    Then I should see a temporary diff comment form

  @javascript
  Scenario: I have a cancel button on the diff form
    Given I open a diff comment form
    Then I should see the cancel comment button

  @javascript
  Scenario: I can cancel a diff form
    Given I open a diff comment form
    And I cancel the diff comment
    Then I should not see the diff comment form

  @javascript
  Scenario: I can't open a second form for a diff line
    Given I open a diff comment form
    And I open a diff comment form
    Then I should only see one diff form

  @javascript
  Scenario: I can have multiple forms
    Given I open a diff comment form
    And I write a diff comment like ":-1: I don't like this"
    And I open another diff comment form
    Then I should see a diff comment form with ":-1: I don't like this"
    And I should see an empty diff comment form

  @javascript
  Scenario: I can preview multiple forms separately
    Given I preview a diff comment text like "Should fix it :smile:"
    And I preview another diff comment text like "DRY this up"
    Then I should see two separate previews

  @javascript
  Scenario: I have a reply button in discussions
    Given I leave a diff comment like "Typo, please fix"
    Then I should see a discussion reply button

  @javascript
  Scenario: I can't preview without text
    Given I open a diff comment form
    And I haven't written any diff comment text
    Then I should not see the diff comment preview button

  @javascript
  Scenario: I can preview with text
    Given I open a diff comment form
    And I write a diff comment like ":-1: I don't like this"
    Then I should see the diff comment preview button

  @javascript
  Scenario: I preview a diff comment
    Given I preview a diff comment text like "Should fix it :smile:"
    Then I should see the diff comment preview
    And I should not see the diff comment text field

  @javascript
  Scenario: I can edit after preview
    Given I preview a diff comment text like "Should fix it :smile:"
    Then I should see the diff comment edit button

  @javascript
  Scenario: The form gets removed after posting
    Given I preview a diff comment text like "Should fix it :smile:"
    And I submit the diff comment
    Then I should not see the diff comment form
    And I should see a discussion reply button


  #@wip @javascript
  #Scenario: I can delete a discussion comment
  #  Given I leave a diff comment like "Typo, please fix"
  #  And I delete a diff comment
  #  Then I should not see a diff comment saying "Typo, please fix"
