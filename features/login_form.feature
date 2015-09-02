Feature: Login form
  Scenario: I see crowd form
    Given Crowd integration enabled
    When I visit sign in page
    Then I should see Crowd login form