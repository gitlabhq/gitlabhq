Feature: User
  Background:
    Given public user "John Van Public"
    And internal user "John Van Internal"
    And private user "John Van Private"

  Scenario: I visit user "John Van Public" page while not logged in
    When I visit user "John Van Public" page
    Then I should see user "John Van Public" page

  Scenario: I visit user "John Van Internal" page while logged in
    Given I sign in as a user
    When I visit user "John Van Internal" page
    Then I should see user "John Van Internal" page

  Scenario: I visit user "John Van Internal" page while not logged in
    When I visit user "John Van Internal" page
    Then I should be redirected to sign in page

  Scenario: I visit user "John Van Private" page while not logged in
    When I visit user "John Van Private" page
    Then I should be redirected to sign in page

  Scenario: I visit user "John Van Private" page while logged in as someone else
    Given I sign in as a user
    When I visit user "John Van Private" page
    Then page status code should be 404

  Scenario: I visit user "John Van Private" page while logged in as "John Van Private"
    Given I sign in as "John Van Private"
    When I visit user "John Van Private" page
    Then I should see user "John Van Private" page
