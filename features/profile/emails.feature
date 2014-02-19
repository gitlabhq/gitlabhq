Feature: Profile Emails
  Background:
    Given I sign in as a user
    And I visit profile emails page

  Scenario: I should see emails
    Then I should see my emails

  Scenario: Add new email
    Given I submit new email "my@email.com"
    Then I should see new email "my@email.com"
    And I should see my emails

  Scenario: Add duplicate email
    Given I submit duplicate email @user.email
    Then I should not have @user.email added
    And I should see my emails

  Scenario: Remove email
    Given I submit new email "my@email.com"
    Then I should see new email "my@email.com"
    And I should see my emails
    Then I click link "Remove" for "my@email.com"
    Then I should not see email "my@email.com"
    And I should see my emails
