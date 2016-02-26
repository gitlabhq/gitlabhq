Feature: Login form
  Scenario: I see Crowd form
    Given Crowd integration enabled
    When I visit sign in page
    Then I should see Crowd login form

  Scenario: I see Crowd form when sign-in is disabled
    Given Crowd integration enabled
    And Sign-in is disabled
    When I visit sign in page
    Then I should see Crowd login form
