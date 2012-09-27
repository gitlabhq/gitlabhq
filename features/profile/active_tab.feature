Feature: Profile active tab
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

  Scenario: On Profile Design
    Given I visit profile design page
    Then the active main tab should be Design
    And no other main tabs should be active

  Scenario: On Profile History
    Given I visit profile history page
    Then the active main tab should be History
    And no other main tabs should be active
