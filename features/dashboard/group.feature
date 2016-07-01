@dashboard
Feature: Dashboard Group
  Background:
    Given I sign in as "John Doe"
    And "John Doe" is owner of group "Owned"
    And "John Doe" is guest of group "Guest"

  Scenario: Create a group from dasboard
    And I visit dashboard groups page
    And I click new group link
    And submit form with new group "Samurai" info
    Then I should be redirected to group "Samurai" page
    And I should see newly created group "Samurai"
