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
    Then I should see "Foo" link in the search results
    And I should not see "Bar" link in the search results

  Scenario: I should see merge requests I am looking for
    And project has merge requests
    When I search for "Foo"
    When I click "Merge requests" link
    Then I should see "Foo" link in the search results
    And I should not see "Bar" link in the search results

  Scenario: I should see milestones I am looking for
    And project has milestones
    When I search for "Foo"
    When I click "Milestones" link
    Then I should see "Foo" link in the search results
    And I should not see "Bar" link in the search results

  Scenario: I should see project code I am looking for
    When I click project "Shop" link
    And I search for "rspec"
    Then I should see code results for project "Shop"

  Scenario: I should see project issues
    And project has issues
    When I click project "Shop" link
    And I search for "Foo"
    And I click "Issues" link
    Then I should see "Foo" link in the search results
    And I should not see "Bar" link in the search results

  Scenario: I should see project merge requests
    And project has merge requests
    When I click project "Shop" link
    And I search for "Foo"
    And I click "Merge requests" link
    Then I should see "Foo" link in the search results
    And I should not see "Bar" link in the search results

  Scenario: I should see project milestones
    And project has milestones
    When I click project "Shop" link
    And I search for "Foo"
    And I click "Milestones" link
    Then I should see "Foo" link in the search results
    And I should not see "Bar" link in the search results

  Scenario: I should see Wiki blobs
    And project has Wiki content
    When I click project "Shop" link
    And I search for "Wiki content"
    And I click "Wiki" link
    Then I should see "test_wiki" link in the search results

  Scenario: I logout and should see project I am looking for
    Given project "Shop" is public
    And I logout
    And I search for "Sho"
    Then I should see "Shop" project link

  Scenario: I logout and should see issues I am looking for
    Given project "Shop" is public
    And I logout
    And project has issues
    When I search for "Foo"
    And I click "Issues" link
    Then I should see "Foo" link in the search results
    And I should not see "Bar" link in the search results

  Scenario: I logout and should see project code I am looking for
    Given project "Shop" is public
    And I logout
    When I visit project "Shop" page
    And I search for "rspec" on project page
    Then I should see code results for project "Shop"
