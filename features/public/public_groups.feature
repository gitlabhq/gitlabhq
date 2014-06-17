@public
Feature: Public Projects Feature
  Background:
    Given group "TestGroup" has private project "Enterprise"

  Scenario: I should not see group with private projects as visitor
    When I visit group "TestGroup" page
    Then I should be redirected to sign in page

  Scenario: I should not see group with private projects group as user
    When I sign in as a user
    And I visit group "TestGroup" page
    Then page status code should be 404

  Scenario: I should not see group with private and internal projects as visitor
    Given group "TestGroup" has internal project "Internal"
    When I visit group "TestGroup" page
    Then I should be redirected to sign in page

  Scenario: I should see group with private and internal projects as user
    Given group "TestGroup" has internal project "Internal"
    When I sign in as a user
    And I visit group "TestGroup" page
    Then I should see project "Internal" items
    And I should not see project "Enterprise" items

  Scenario: I should see group issues for internal project as user
    Given group "TestGroup" has internal project "Internal"
    When I sign in as a user
    And I visit group "TestGroup" issues page
    And I change filter to Everyone's
    Then I should see project "Internal" items
    And I should not see project "Enterprise" items

  Scenario: I should see group merge requests for internal project as user
    Given group "TestGroup" has internal project "Internal"
    When I sign in as a user
    And I visit group "TestGroup" merge requests page
    And I change filter to Everyone's
    Then I should see project "Internal" items
    And I should not see project "Enterprise" items

  Scenario: I should see group's members as user
    Given group "TestGroup" has internal project "Internal"
    And "John Doe" is owner of group "TestGroup"
    When I sign in as a user
    And I visit group "TestGroup" members page
    Then I should see group member "John Doe"
    And I should not see member roles

  Scenario: I should see group with private, internal and public projects as visitor
    Given group "TestGroup" has internal project "Internal"
    Given group "TestGroup" has public project "Community"
    When I visit group "TestGroup" page
    Then I should see project "Community" items
    And I should not see project "Internal" items
    And I should not see project "Enterprise" items

  Scenario: I should see group issues for public project as visitor
    Given group "TestGroup" has internal project "Internal"
    Given group "TestGroup" has public project "Community"
    When I visit group "TestGroup" issues page
    Then I should see project "Community" items
    And I should not see project "Internal" items
    And I should not see project "Enterprise" items

  Scenario: I should see group merge requests for public project as visitor
    Given group "TestGroup" has internal project "Internal"
    Given group "TestGroup" has public project "Community"
    When I visit group "TestGroup" merge requests page
    Then I should see project "Community" items
    And I should not see project "Internal" items
    And I should not see project "Enterprise" items

  Scenario: I should see group's members as visitor
    Given group "TestGroup" has internal project "Internal"
    Given group "TestGroup" has public project "Community"
    And "John Doe" is owner of group "TestGroup"
    When I visit group "TestGroup" members page
    Then I should see group member "John Doe"
    And I should not see member roles

  Scenario: I should see group with private, internal and public projects as user
    Given group "TestGroup" has internal project "Internal"
    Given group "TestGroup" has public project "Community"
    When I sign in as a user
    And I visit group "TestGroup" page
    Then I should see project "Community" items
    And I should see project "Internal" items
    And I should not see project "Enterprise" items

  Scenario: I should see group issues for internal and public projects as user
    Given group "TestGroup" has internal project "Internal"
    Given group "TestGroup" has public project "Community"
    When I sign in as a user
    And I visit group "TestGroup" issues page
    And I change filter to Everyone's
    Then I should see project "Community" items
    And I should see project "Internal" items
    And I should not see project "Enterprise" items

  Scenario: I should see group merge requests for internal and public projects as user
    Given group "TestGroup" has internal project "Internal"
    Given group "TestGroup" has public project "Community"
    When I sign in as a user
    And I visit group "TestGroup" merge requests page
    And I change filter to Everyone's
    Then I should see project "Community" items
    And I should see project "Internal" items
    And I should not see project "Enterprise" items

  Scenario: I should see group's members as user
    Given group "TestGroup" has internal project "Internal"
    Given group "TestGroup" has public project "Community"
    And "John Doe" is owner of group "TestGroup"
    When I sign in as a user
    And I visit group "TestGroup" members page
    Then I should see group member "John Doe"
    And I should not see member roles
