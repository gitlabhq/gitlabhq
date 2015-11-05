@profile
Feature: Profile
  Background:
    Given I sign in as a user

  Scenario: I look at my profile
    Given I visit profile page
    Then I should see my profile info

  @javascript
  Scenario: I can see groups I belong to
    Given I have group with projects
    When I visit profile page
    And I click on my profile picture
    Then I should see my user page
    And I should see groups I belong to

  Scenario: I edit profile
    Given I visit profile page
    Then I change my profile info
    And I should see new profile info

  Scenario: I change my password without old one
    Given I visit profile password page
    When I try change my password w/o old one
    Then I should see a missing password error message
    And I should be redirected to password page

  Scenario: I change my password
    Given I visit profile password page
    Then I change my password
    And I should be redirected to sign in page

  Scenario: I edit my avatar
    Given I visit profile page
    Then I change my avatar
    And I should see new avatar
    And I should see the "Remove avatar" button
    And I should see the gravatar host link

  Scenario: I remove my avatar
    Given I visit profile page
    And I have an avatar
    When I remove my avatar
    Then I should see my gravatar
    And I should not see the "Remove avatar" button
    And I should see the gravatar host link

  Scenario: My password is expired
    Given my password is expired
    And I am not an ldap user
    Given I visit profile password page
    Then I redirected to expired password page
    And I submit new password
    And I redirected to sign in page

  Scenario: I unsuccessfully change my password
    Given I visit profile password page
    When I unsuccessfully change my password
    Then I should see a password error message

  Scenario: I reset my token
    Given I visit profile account page
    Then I reset my token
    And I should see new token

  Scenario: I visit history tab
    Given I have activity
    When I visit Audit Log page
    Then I should see my activity

  Scenario: I visit my user page
    When I visit profile page
    And I click on my profile picture
    Then I should see my user page

  Scenario: I can manage application
    Given I visit profile applications page
    Then I click on new application button
    And I should see application form
    Then I fill application form out and submit
    And I see application
    Then I click edit
    And I see edit application form
    Then I change name of application and submit
    And I see that application was changed
    Then I visit profile applications page
    And I click to remove application
    Then I see that application is removed
