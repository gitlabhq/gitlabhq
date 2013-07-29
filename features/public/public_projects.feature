Feature: Public Projects Feature
  Background:
    Given public project "Community"
    And private project "Enterprise"

  Scenario: I visit public area
    When I visit the public projects area
    Then I should see project "Community"
    And I should not see project "Enterprise"

  Scenario: I visit public project page
    When I visit public page for "Community" project
    Then I should see public project details
    And I should see project readme
