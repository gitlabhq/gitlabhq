Feature: Public Projects Feature
  Background:
    Given public project "Community"
    And private project "Enterprise"

  Scenario: I visit public area
    When I visit the public projects area
    Then I should see project "Community"
    And I should not see project "Enterprise"

  Scenario: I visit public project page
    When I visit project "Community" page
    Then I should see project "Community" home page

  Scenario: I visit an empty public project page
    Given public empty project "Empty Public Project"
    When I visit empty project page
    Then I should see empty public project details
