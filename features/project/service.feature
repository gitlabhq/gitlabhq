Feature: Project Services
  Background:
    Given I sign in as a user
    And I own project "Shop"

  Scenario: I should see project services
    When I visit project "Shop" services page
    Then I should see list of available services

  Scenario: Activate hipchat service
    When I visit project "Shop" services page
    And I click hipchat service link
    And I fill hipchat settings
    Then I should see the Hipchat success message

  Scenario: Activate hipchat service with custom server
    When I visit project "Shop" services page
    And I click hipchat service link
    And I fill hipchat settings with custom server
    Then I should see the Hipchat success message

  Scenario: Activate pivotaltracker service
    When I visit project "Shop" services page
    And I click pivotaltracker service link
    And I fill pivotaltracker settings
    Then I should see the Pivotaltracker success message

  Scenario: Activate Flowdock service
    When I visit project "Shop" services page
    And I click Flowdock service link
    And I fill Flowdock settings
    Then I should see the Flowdock success message

  Scenario: Activate Assembla service
    When I visit project "Shop" services page
    And I click Assembla service link
    And I fill Assembla settings
    Then I should see the Assembla success message

  Scenario: Activate Slack notifications service
    When I visit project "Shop" services page
    And I click Slack notifications service link
    And I fill Slack notifications settings
    Then I should see the Slack notifications success message

  Scenario: Activate Pushover service
    When I visit project "Shop" services page
    And I click Pushover service link
    And I fill Pushover settings
    Then I should see the Pushover success message

  Scenario: Activate email on push service
    When I visit project "Shop" services page
    And I click email on push service link
    And I fill email on push settings
    Then I should see the Emails on push success message

  Scenario: Activate JIRA service
    When I visit project "Shop" services page
    And I click jira service link
    And I fill jira settings
    Then I should see the JIRA success message

  Scenario: Activate Irker (IRC Gateway) service
    When I visit project "Shop" services page
    And I click Irker service link
    And I fill Irker settings
    Then I should see the Irker success message

  Scenario: Activate Atlassian Bamboo CI service
    When I visit project "Shop" services page
    And I click Atlassian Bamboo CI service link
    And I fill Atlassian Bamboo CI settings
    Then I should see the Bamboo success message
    And I should see empty field Change Password

  Scenario: Activate jetBrains TeamCity CI service
    When I visit project "Shop" services page
    And I click jetBrains TeamCity CI service link
    And I fill jetBrains TeamCity CI settings
    Then I should see the JetBrains success message

  Scenario: Activate Asana service
    When I visit project "Shop" services page
    And I click Asana service link
    And I fill Asana settings
    Then I should see the Asana success message
