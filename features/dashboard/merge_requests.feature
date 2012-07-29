Feature: Dashboard MR
  Background: 
    Given I signin as a user
    And I have authored merge requests
    And I visit dashboard merge requests page 

  Scenario: I should see projects list
    Then I should see my merge requests
