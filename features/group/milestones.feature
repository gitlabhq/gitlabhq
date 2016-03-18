Feature: Group Milestones
  Background:
    Given I sign in as "John Doe"
    And "John Doe" is owner of group "Owned"

  Scenario: I should see group "Owned" milestone index page with no milestones
    When I visit group "Owned" page
    And I click on group milestones
    Then I should see group milestones index page has no milestones

  Scenario: I should see group "Owned" milestone index page with milestones
    Given Group has projects with milestones
    When I visit group "Owned" page
    And I click on group milestones
    Then I should see group milestones index page with milestones

  Scenario: I should see group "Owned" milestone show page
    Given Group has projects with milestones
    When I visit group "Owned" page
    And I click on group milestones
    And I click on one group milestone
    Then I should see group milestone with descriptions and expiry date
    And I should see group milestone with all issues and MRs assigned to that milestone

  Scenario: Create multiple milestones with one form
    Given I visit group "Owned" milestones page
    And I click new milestone button
    And I fill milestone name
    When I press create mileston button
    Then milestone in each project should be created

  Scenario: I should see Issues listed with labels
    Given Group has projects with milestones
    When I visit group "Owned" page
    And I click on group milestones
    And I click on one group milestone
    Then I should see the "bug" label
    And I should see the "feature" label
    And I should see the project name in the Issue row

  Scenario: I should see the Labels tab
    Given Group has projects with milestones
    When I visit group "Owned" page
    And I click on group milestones
    And I click on one group milestone
    And I click on the "Labels" tab
    Then I should see the list of labels
