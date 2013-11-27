Feature: Project Browse commits
  Background:
    Given I sign in as a user
    And I own a project
    And I visit my project's commits page

  Scenario: I browse commits list for master branch
    Then I see project commits

  Scenario: I browse atom feed of commits list for master branch
    Given I click atom feed link
    Then I see commits atom feed

  Scenario: I browse commit from list
    Given I click on commit link
    Then I see commit info
    And I see side-by-side diff button

  Scenario: I browse commit with side-by-side diff view
    Given I click on commit link
    And I click side-by-side diff button
    Then I see inline diff button

  Scenario: I compare refs
    Given I visit compare refs page
    And I fill compare fields with refs
    Then I see compared refs

  Scenario: I browse commits for a specific path
    Given I visit my project's commits page for a specific path
    Then I see breadcrumb links

  Scenario: I browse commits stats
    Given I visit my project's commits stats page
    Then I see commits stats

  Scenario: I browse big commit
    Given I visit big commit page
    Then I see big commit warning

  Scenario: I browse huge commit
    Given I visit huge commit page
    Then I see huge commit message

  Scenario: I browse a commit with an image
    Given I visit a commit with an image that changed
    Then The diff links to both the previous and current image
