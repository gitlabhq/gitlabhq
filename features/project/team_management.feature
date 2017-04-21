Feature: Project Team Management
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And gitlab user "Mike"
    And gitlab user "Dmitriy"
    And "Dmitriy" is "Shop" developer
    And I visit project "Shop" team page

  Scenario: Cancel team member
    Given I click cancel link for "Dmitriy"
    Then I visit project "Shop" team page
    And I should not see "Dmitriy" in team list

  Scenario: Import team from another project
    Given I own project "Website"
    And "Mike" is "Website" reporter
    When I visit project "Shop" team page
    And I click link "Import team from another project"
    And I submit "Website" project for import team
    Then I should see "Mike" in team list as "Reporter"

  Scenario: See all members of projects shared group
    Given I share project with group "OpenSource"
    And I visit project "Shop" team page
    Then I should see "Opensource" group user listing
