Feature: Project Team management
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And gitlab user "Mike"
    And gitlab user "Sam"
    And "Sam" is "Shop" developer
    And I visit project "Shop" team page

  Scenario: See all team members
    Then I should be able to see myself in team
    And I should see "Sam" in team list

  Scenario: Add user to project
    Given I click link "New Team Member"
    And I select "Mike" as "Reporter"
    Then I should see "Mike" in team list as "Reporter"

  @javascript
  Scenario: Update user access
    Given I should see "Sam" in team list as "Developer"
    And I change "Sam" role to "Reporter"
    Then I visit project "Shop" team page
    And I should see "Sam" in team list as "Reporter"

  Scenario: View team member profile
    Given I click link "Sam"
    Then I should see "Sam" team profile

  Scenario: Cancel team member
    Given I click link "Sam"
    And I click link "Remove from team"
    Then I visit project "Shop" team page
    And I should not see "Sam" in team list
