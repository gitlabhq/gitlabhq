Feature: Comments on commits
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And I visit project commit page

  @javascript
  Scenario: I can comment on a commit
    Given I leave a comment like "XML attached"
    Then I should see a comment saying "XML attached"

  @javascript
  Scenario: I can't cancel the main form
    Then I should not see the cancel comment button

  @javascript
  Scenario: I can delete a comment
    Given I leave a comment like "XML attached"
    And I delete a comment
    Then I should not see a comment saying "XML attached"

  # Preview

  @javascript
  Scenario: I can't preview without text
    Given I haven't written any comment text
    Then The markdown preview button should be disabled

  @javascript
  Scenario: I can preview with text
    Given I write a comment like "Nice"
    Then The markdown preview button should be enabled

  @javascript
  Scenario: I preview a comment
    Given I preview a markdown input with a header
    Then I should see the markdown preview
    And I should not see the markdown input field
    And The preview header should not have an id

  @javascript
  Scenario: I can edit after preview
    Given I preview a markdown input with a header
    Then I should see the markdown edit button
    When I click the markdown edit button
    Then I should see the markdown input field
    And The input should be the header input

  @javascript
  Scenario: I have a reset form after posting from preview
    Given I preview a markdown input with a header
    And I submit the comment
    Then I should see an empty comment text field
    And I should not see the markdown preview
    Then The markdown preview button should be disabled
