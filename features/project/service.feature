Feature: Project Services
  Background:
    Given I sign in as a user
    And I own project "Shop"

  Scenario: I should see project services
    When I visit project "Shop" services page
    Then I should see list of available services

  Scenario: Activate gitlab-ci service
    When I visit project "Shop" services page
    And I click gitlab-ci service link
    And I fill gitlab-ci settings
    Then I should see service settings saved

  Scenario: Activate hipchat service
    When I visit project "Shop" services page
    And I click hipchat service link
    And I fill hipchat settings
    Then I should see hipchat service settings saved

  Scenario: Activate hipchat service with custom server
    When I visit project "Shop" services page
    And I click hipchat service link
    And I fill hipchat settings with custom server
    Then I should see hipchat service settings with custom server saved

  Scenario: Activate pivotaltracker service
    When I visit project "Shop" services page
    And I click pivotaltracker service link
    And I fill pivotaltracker settings
    Then I should see pivotaltracker service settings saved

  Scenario: Activate Flowdock service
    When I visit project "Shop" services page
    And I click Flowdock service link
    And I fill Flowdock settings
    Then I should see Flowdock service settings saved

  Scenario: Activate Assembla service
    When I visit project "Shop" services page
    And I click Assembla service link
    And I fill Assembla settings
    Then I should see Assembla service settings saved

  Scenario: Activate Slack service
    When I visit project "Shop" services page
    And I click Slack service link
    And I fill Slack settings
    Then I should see Slack service settings saved

  Scenario: Activate Pushover service
    When I visit project "Shop" services page
    And I click Pushover service link
    And I fill Pushover settings
    Then I should see Pushover service settings saved

  Scenario: Activate email on push service
    When I visit project "Shop" services page
    And I click email on push service link
    And I fill email on push settings
    Then I should see email on push service settings saved

  Scenario: Activate Irker (IRC Gateway) service
    When I visit project "Shop" services page
    And I click Irker service link
    And I fill Irker settings
    Then I should see Irker service settings saved

  Scenario: Activate Atlassian Bamboo CI service
    When I visit project "Shop" services page
    And I click Atlassian Bamboo CI service link
    And I fill Atlassian Bamboo CI settings
    Then I should see Atlassian Bamboo CI service settings saved
    And I should see empty field Change Password

  Scenario: Activate jetBrains TeamCity CI service
    When I visit project "Shop" services page
    And I click jetBrains TeamCity CI service link
    And I fill jetBrains TeamCity CI settings
    Then I should see jetBrains TeamCity CI service settings saved

  Scenario: Activate Asana service
    When I visit project "Shop" services page
    And I click Asana service link
    And I fill Asana settings
    Then I should see Asana service settings saved
