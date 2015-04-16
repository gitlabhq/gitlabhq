Feature: Invites
  Background:
    Given "John Doe" is owner of group "Owned"
    And "John Doe" has invited "user@example.com" to group "Owned"

  Scenario: Viewing invitation when signed out
    When I visit the invitation page
    Then I should be redirected to the sign in page
    And I should see a notice telling me to sign in

  Scenario: Signing in to view invitation
    When I visit the invitation page
    And I sign in as "Mary Jane"
    Then I should be redirected to the invitation page

  Scenario: Viewing invitation when signed in
    Given I sign in as "Mary Jane"
    And I visit the invitation page
    Then I should see the invitation details
    And I should see an "Accept invitation" button
    And I should see a "Decline" button

  Scenario: Viewing invitation as an existing member
    Given I sign in as "John Doe"
    And I visit the invitation page
    Then I should see a message telling me I'm already a member

  Scenario: Accepting the invitation
    Given I sign in as "Mary Jane"
    And I visit the invitation page
    And I click the "Accept invitation" button
    Then I should be redirected to the group page
    And I should see a notice telling me I have access

  Scenario: Declining the application when signed in
    Given I sign in as "Mary Jane"
    And I visit the invitation page
    And I click the "Decline" button
    Then I should be redirected to the dashboard
    And I should see a notice telling me I have declined

  Scenario: Declining the application when signed out
    When I visit the invitation's decline page
    Then I should be redirected to the sign in page
    And I should see a notice telling me I have declined
