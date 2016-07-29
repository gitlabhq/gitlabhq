@admin
Feature: Admin Users
  Background:
    Given I sign in as an admin
    And system has users

  Scenario: On Admin Users
    Given I visit admin users page
    Then I should see all users

  Scenario: Edit user and change username to non ascii char
    When I visit admin users page
    And Click edit
    And Input non ascii char in username
    And Click save
    Then See username error message
    And Not changed form action url

  Scenario: Show user attributes
    Given user "Mike" with groups and projects
    Given I visit admin users page
    And click on "Mike" link
    Then I should see user "Mike" details

  Scenario: Edit my user attributes
    Given I visit admin users page
    And click edit on my user
    When I submit modified user
    Then I see user attributes changed

  @javascript
  Scenario: Remove users secondary email
    Given I visit admin users page
    And I view the user with secondary email
    And I see the secondary email
    When I click remove secondary email
    Then I should not see secondary email anymore

  Scenario: Show user keys
    Given user "Pete" with ssh keys
    And I visit admin users page
    And click on user "Pete"
    And click on ssh keys tab
    Then I should see key list
    And I click on the key title
    Then I should see key details
    And I click on remove key
    Then I should see the key removed

  Scenario: Show user identities
    Given user "Pete" with twitter account
    And I visit "Pete" identities page in admin
    Then I should see twitter details

  Scenario: Update user identities
    Given user "Pete" with twitter account
    And I visit "Pete" identities page in admin
    And I modify twitter identity
    Then I should see twitter details updated

  Scenario: Remove user identities
    Given user "Pete" with twitter account
    And I visit "Pete" identities page in admin
    And I remove twitter identity
    Then I should not see twitter details

  Scenario: Add note to user attributes
    Given I visit admin users page
    And click edit on my user
    When I submit a note
    Then I see note tooltip
