Feature: Public Users
  Background:
    Given public user "John Van Public"
    And internal user "John Van Internal"
    And private user "John Van Private"

  Scenario: I visit the public users area while not logged in
    When I visit the public users area
    Then I should see user "John Van Public"
    And I should not see user "John Van Internal"
    And I should not see user "John Van Private"

  Scenario: I visit public users area while logged in
    Given I sign in as a user
    When I visit the public users area
    Then I should see user "John Van Public"
    And I should see user "John Van Internal"
    And I should not see user "John Van Private"

  Scenario: I search for an user
    Given I sign in as a user
    And I visit the public users area
    When I search for user "inter"
    Then I should not see user "John Van Public"
    And I should see user "John Van Internal"
