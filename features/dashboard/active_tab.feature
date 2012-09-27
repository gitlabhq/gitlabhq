Feature: Dashboard active tab
  Background:
    Given I sign in as a user

  Scenario: On Dashboard Home
    Given I visit dashboard page
    Then the active main tab should be Home
    And no other main tabs should be active

  Scenario: On Dashboard Issues
    Given I visit dashboard issues page
    Then the active main tab should be Issues
    And no other main tabs should be active

  Scenario: On Dashboard Merge Requests
    Given I visit dashboard merge requests page
    Then the active main tab should be Merge Requests
    And no other main tabs should be active

  Scenario: On Dashboard Search
    Given I visit dashboard search page
    Then the active main tab should be Search
    And no other main tabs should be active

  Scenario: On Dashboard Help
    Given I visit dashboard help page
    Then the active main tab should be Help
    And no other main tabs should be active
