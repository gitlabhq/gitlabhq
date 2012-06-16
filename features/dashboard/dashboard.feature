Feature: Dashboard
  Background: 
    Given I signin as a user
    And I own project "Shop"
    And project "Shop" has push event
    And I visit dashboard page 

  Scenario: I should see projects list
    Then I should see "New Project" link
    Then I should see "Shop" project link
    Then I should see project "Shop" activity feed

  Scenario: I should see last pish widget
    Then I should see last push widget
    And I click "Create Merge Request" link
    Then I see prefilled new Merge Request page


