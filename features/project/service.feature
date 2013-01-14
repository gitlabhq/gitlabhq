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
