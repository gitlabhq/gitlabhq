Feature: Dashboard Search
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And Project "Shop" has wiki page "Contibuting guide"
    And I visit dashboard search page

  Scenario: I should see project I am looking for
    Given I search for "Sho"
    Then I should see "Shop" project link

  Scenario: I should see wiki page I am looking for
    Given I search for "Contibuting"
    Then I should see "Contibuting guide" wiki link