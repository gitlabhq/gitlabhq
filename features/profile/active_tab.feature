@profile
Feature: Profile Active Tab
  Background:
    Given I sign in as a user

  Scenario: On Profile Home
    Given I visit profile page
    Then the active main tab should be Home
    And no other main tabs should be active

  Scenario: On Profile Account
    Given I visit profile account page
    Then the active main tab should be Account
    And no other main tabs should be active

  Scenario: On Profile SSH Keys
    Given I visit profile SSH keys page
    Then the active main tab should be SSH Keys
    And no other main tabs should be active

  Scenario: On Profile Preferences
    Given I visit profile preferences page
    Then the active main tab should be Preferences
    And no other main tabs should be active

  Scenario: On Profile Audit Log
    Given I visit Audit Log page
    Then the active main tab should be Audit Log
    And no other main tabs should be active
