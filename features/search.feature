@dashboard
Feature: Search
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And I visit dashboard search page

  Scenario: I should see project I am looking for
    Given I search for "Sho"
    Then I should see "Shop" project link

  Scenario: I should see issues I am looking for
    And project has issues
    When I search for "Foo"
    And I click "Issues" link
    Then I should see "Foo" link
    And I should not see "Bar" link

  Scenario: I should see merge requests I am looking for
    And project has merge requests
    When I search for "Foo"
    When I click "Merge requests" link
    Then I should see "Foo" link
    And I should not see "Bar" link

  Scenario: I should see project code I am looking for
    When I search for "rspec"
    And I click project "Shop" link
    Then I should see code results for project "Shop"
