Feature: Project Browse Commits User Lookup
  Background:
    Given I sign in as a user
    And I own a project
    And I have the user that authored the commits
    And I visit my project's commits page

  Scenario: I browse commit from list
    Given I click on commit link
    Then I see commit info

  Scenario: I browse another commit from list
    Given I click on another commit link
    Then I see other commit info
