Feature: Project Team Management
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And gitlab user "Mike"
    And gitlab user "Dmitriy"
    And "Dmitriy" is "Shop" developer
    And I visit project "Shop" team page

  Scenario: See all team members
    Then I should be able to see myself in team
    And I should see "Dmitriy" in team list

  @javascript
  Scenario: Add user to project
    When I select "Mike" as "Reporter"
    Then I should see "Mike" in team list as "Reporter"

  @javascript
  Scenario: Invite user to project
    When I select "sjobs@apple.com" as "Reporter"
    Then I should see "sjobs@apple.com" in team list as invited "Reporter"

  @javascript
  Scenario: Update user access
    Given I should see "Dmitriy" in team list as "Developer"
    And I change "Dmitriy" role to "Reporter"
    And I should see "Dmitriy" in team list as "Reporter"

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
