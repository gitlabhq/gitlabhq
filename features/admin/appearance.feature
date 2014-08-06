Feature: Admin Appearance
  Scenario: Create new appearance
    Given I sign in as an admin
    And I visit admin appearance page
    When submit form with new appearance
    Then I should be redirected to admin appearance page
    And I should see newly created appearance

  Scenario: Preview appearance
    Given application has custom appearance
    And I sign in as an admin
    When I visit admin appearance page
    And I click preview button
    Then I should see a customized appearance

  Scenario: Custom sign-in page
    Given application has custom appearance
    When I visit login page
    Then I should see a customized appearance
