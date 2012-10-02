Feature: Profile
  Background:
    Given I sign in as a user

  Scenario: I look at my profile
    Given I visit profile page
    Then I should see my profile info

  Scenario: I edit profile
    Given I visit profile page
    Then I change my contact info
    And I should see new contact info

  Scenario: I change my password
    Given I visit profile account page
    Then I change my password
    And I should be redirected to sign in page

  Scenario: I reset my token
    Given I visit profile account page
    Then I reset my token
    And I should see new token

  Scenario: I visit history tab
    Given I have activity
    When I visit profile history page
    Then I should see my activity
