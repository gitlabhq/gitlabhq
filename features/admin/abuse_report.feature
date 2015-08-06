Feature: Admin Abuse reports
  Background:
    Given I sign in as an admin
    And abuse reports exist

  Scenario: Browse abuse reports
    When I visit abuse reports page
    Then I should see list of abuse reports
