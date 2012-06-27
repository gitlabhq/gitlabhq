Feature: Issues
  Background:
    Given I signin as a user
    And I own project "Shop"
    And project "Shop" have "Release 0.4" open issue
    And project "Shop" have "Release 0.3" closed issue
    And I visit project "Shop" issues page 

  Scenario: I should see open issues
    Given I should see "Release 0.4" open issue
    And I should not see "Release 0.3" closed issue   

