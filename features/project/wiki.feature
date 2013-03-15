Feature: Project Wiki
  Background:
    Given I sign in as a user
    And I own project "Shop"
    Given I visit project wiki page

  Scenario: Add new page
    Given I create the Wiki Home page
    Then I should see the newly created wiki page

  Scenario: Edit existing page
    Given I have an existing Wiki page
    And I browse to that Wiki page
    And I click on the Edit button
    And I change the content
    Then I should see the updated content

  Scenario: View page history
    Given I have an existing wiki page
    And That page has two revisions
    And I browse to that Wiki page
    And I click the History button
    Then I should see both revisions

  Scenario: Destroy Wiki page
    Given I have an existing wiki page
    And I browse to that Wiki page
    And I click on the Edit button
    And I click on the "Delete this page" button
    Then The page should be deleted

  Scenario: View all pages
    Given I have an existing wiki page
    And I browse to that Wiki page
    And I click on the "Pages" button
    Then I should see the existing page in the pages list
