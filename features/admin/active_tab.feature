@admin
Feature: Admin Active Tab
  Background:
    Given I sign in as an admin

  Scenario: On Admin Home
    Given I visit admin page
    Then the active main tab should be Overview
    And no other main tabs should be active

  Scenario: On Admin Projects
    Given I visit admin projects page
    Then the active main tab should be Overview
    And the active sub tab should be Projects
    And no other main tabs should be active
    And no other sub tabs should be active

  Scenario: On Admin Groups
    Given I visit admin groups page
    Then the active main tab should be Overview
    And the active sub tab should be Groups
    And no other main tabs should be active
    And no other sub tabs should be active

  Scenario: On Admin Users
    Given I visit admin users page
    Then the active main tab should be Overview
    And the active sub tab should be Users
    And no other main tabs should be active
    And no other sub tabs should be active

  Scenario: On Admin Logs
    Given I visit admin logs page
    Then the active main tab should be Monitoring
    And the active sub tab should be Logs
    And no other main tabs should be active
    And no other sub tabs should be active

  Scenario: On Admin Messages
    Given I visit admin messages page
    Then the active main tab should be Messages
    And no other main tabs should be active

  Scenario: On Admin Hooks
    Given I visit admin hooks page
    Then the active main tab should be Hooks
    And no other main tabs should be active

  Scenario: On Admin Resque
    Given I visit admin Resque page
    Then the active main tab should be Monitoring
    And the active sub tab should be Resque
    And no other main tabs should be active
    And no other sub tabs should be active
