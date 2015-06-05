@admin
Feature: Admin Deploy Keys
  Background:
    Given I sign in as an admin
    And there are public deploy keys in system

  Scenario: Deploy Keys list
    When I visit admin deploy keys page
    Then I should see all public deploy keys

  Scenario: Deploy Keys new
    When I visit admin deploy keys page
    And I click 'New Deploy Key'
    And I submit new deploy key
    Then I should be on admin deploy keys page
    And I should see newly created deploy key
