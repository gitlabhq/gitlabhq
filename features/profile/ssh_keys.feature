Feature: SSH Keys
  Background: 
    Given I signin as a user
    And I have ssh keys:
      | title | 
      | Work |
      | Home | 
    And I visit profile keys page

  Scenario: I should see SSH keys
    Then I should see my ssh keys

  Scenario: Add new ssh key
    Given I click link "Add new"
    And I submit new ssh key "Laptop"
    Then I should see new ssh key "Laptop"

  Scenario: Remove ssh key
    Given I click link "Work"
    And I click link "Remove"
    Then I visit profile keys page
    And I should not see "Work" ssh key
