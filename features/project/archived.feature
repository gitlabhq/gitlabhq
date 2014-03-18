Feature: Project Archived
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And I own project "Forum"

  Scenario: I should not see archived on project page of not-archive project
    And project "Forum" is archived
    And I visit project "Shop" page
    Then I should not see "Archived"

  Scenario: I should see archived on project page of archive project
    And project "Forum" is archived
    And I visit project "Forum" page
    Then I should see "Archived"

  Scenario: I should not see archived on projects page with no archived projects
    And I visit dashboard projects page
    Then I should not see "Archived"

  Scenario: I should see archived on projects page with archived projects
    And project "Forum" is archived
    And I visit dashboard projects page
    Then I should see "Archived"

  Scenario: I archive project
    When project "Shop" has push event
    And I visit project "Shop" page
    And I visit edit project "Shop" page
    And I set project archived
    Then I should see "Archived"

  Scenario: I unarchive project
    When project "Shop" has push event
    And project "Shop" is archived
    And I visit project "Shop" page
    And I visit edit project "Shop" page
    And I set project unarchived
    Then I should not see "Archived"
