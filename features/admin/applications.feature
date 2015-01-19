@admin
Feature: Admin Applications
  Background:
    Given I sign in as an admin
    And I visit applications page
    
  Scenario: I can manage application
    Then I click on new application button
    And I should see application form
    Then I fill application form out and submit
    And I see application
    Then I click edit
    And I see edit application form
    Then I change name of application and submit
    And I see that application was changed
    Then I visit applications page
    And I click to remove application
    Then I see that application is removed