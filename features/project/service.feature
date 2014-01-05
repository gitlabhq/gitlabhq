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

  Scenario: Activate email on push service
    When I visit project "Shop" services page
    And I click email on push service link
    And I fill email on push settings
    Then I should see email on push service settings saved
