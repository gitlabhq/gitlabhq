Feature: Project Commits Tags
  Background:
    Given I sign in as a user
    And I own project "Shop"
    Given I visit project tags page

  Scenario: I can see all git tags
    Then I should see "Shop" all tags list

  Scenario: I create a tag
    And I click new tag link
    And I submit new tag form
    Then I should see new tag created

  Scenario: I create a tag with invalid name
    And I click new tag link
    And I submit new tag form with invalid name
    Then I should see new an error that tag is invalid

  Scenario: I create a tag with invalid reference
    And I click new tag link
    And I submit new tag form with invalid reference
    Then I should see new an error that tag ref is invalid

  Scenario: I create a tag that already exists
    And I click new tag link
    And I submit new tag form with tag that already exists
    Then I should see new an error that tag already exists

  @javascript
  Scenario: I delete a tag
    Given I delete tag 'v1.1.0'
    Then I should not see tag 'v1.1.0'

  @javascript
  Scenario: I delete all tags and see info message
    Given I delete all tags
    Then I should see tags info message

  # @wip
  # Scenario: I can download project by tag
