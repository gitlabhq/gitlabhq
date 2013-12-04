Feature: Public Projects Feature
  Background:
    Given public project "Community"
    And internal project "Internal"
    And private project "Enterprise"

  Scenario: I visit public area
    When I visit the public projects area
    Then I should see project "Community"
    And I should not see project "Internal"
    And I should not see project "Enterprise"

  Scenario: I visit public project page
    When I visit project "Community" page
    Then I should see project "Community" home page

  Scenario: I visit internal project page
    When I visit project "Internal" page
    Then I should be redirected to sign in page

  Scenario: I visit private project page
    When I visit project "Enterprise" page
    Then I should be redirected to sign in page

  Scenario: I visit an empty public project page
    Given public empty project "Empty Public Project"
    When I visit empty project page
    Then I should see empty public project details
    And I should see empty public project details with http clone info

  Scenario: I visit an empty public project page as user
    Given I sign in as a user
    And public empty project "Empty Public Project"
    When I visit empty project page
    Then I should see empty public project details
    And I should see empty public project details with ssh clone info

  Scenario: I visit public area as user
    Given I sign in as a user
    When I visit the public projects area
    Then I should see project "Community"
    And I should see project "Internal"
    And I should not see project "Enterprise"

  Scenario: I visit internal project page as user
    Given I sign in as a user
    When I visit project "Internal" page
    Then I should see project "Internal" home page

  Scenario: I visit public project page
    When I visit project "Community" page
    Then I should see project "Community" home page
    And I should see an http link to the repository

  Scenario: I visit public project page as user
    Given I sign in as a user
    When I visit project "Community" page
    Then I should see project "Community" home page
    And I should see an ssh link to the repository

  Scenario: I visit an empty public project page
    Given public empty project "Empty Public Project"
    When I visit empty project page
    Then I should see empty public project details
