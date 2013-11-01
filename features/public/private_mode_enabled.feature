Feature: Private Mode Enabled Feature
  Background:
    Given private mode is enabled
    And public project "Community"
    And private project "Enterprise"

  Scenario: I visit public area
    When I visit the public projects area
    Then I should be redirected to sign in page

  Scenario: I visit public project page
    When I visit project "Community" page
    Then I should be redirected to sign in page

  Scenario: I visit public area as an authenticated user
    Given I sign in as a user
    When I visit the public projects area
    Then I should see the list of public projects
    And I should see project "Community"
    And I should not see project "Enterprise"

  Scenario: I visit public project page as an authenticated user
    Given I sign in as a user
    When I visit project "Community" page
    Then I should see project "Community" home page

  Scenario: I visit an empty public project page as an authenticated user
    Given I sign in as a user
    And public empty project "Empty Public Project"
    When I visit empty project page
    Then I should see empty public project details
