Feature: Project active tab
  Background:
    Given I sign in as a user
    And I own a project

  # Main Tabs

  Scenario: On Project Home
    Given I visit my project's home page
    Then the active main tab should be Home
    And no other main tabs should be active

  Scenario: On Project Files
    Given I visit my project's files page
    Then the active main tab should be Files
    And no other main tabs should be active

  Scenario: On Project Commits
    Given I visit my project's commits page
    Then the active main tab should be Commits
    And no other main tabs should be active

  Scenario: On Project Network
    Given I visit my project's network page
    Then the active main tab should be Network
    And no other main tabs should be active

  Scenario: On Project Issues
    Given I visit my project's issues page
    Then the active main tab should be Issues
    And no other main tabs should be active

  Scenario: On Project Merge Requests
    Given I visit my project's merge requests page
    Then the active main tab should be Merge Requests
    And no other main tabs should be active

  Scenario: On Project Wiki
    Given I visit my project's wiki page
    Then the active main tab should be Wiki
    And no other main tabs should be active

  # Sub Tabs: Home

  Scenario: On Project Home/Show
    Given I visit my project's home page
    Then the active main tab should be Home
    And no other main tabs should be active

  # Sub Tabs: Settings

  Scenario: On Project Settings/Team
    Given I visit my project's settings page
    And I click the "Team" tab
    Then the active sub nav should be Team
    And no other sub navs should be active
    And the active main tab should be Settings

  Scenario: On Project Settings/Edit
    Given I visit my project's settings page
    And I click the "Edit" tab
    Then the active sub nav should be Edit
    And no other sub navs should be active
    And the active main tab should be Settings

  Scenario: On Project Settings/Hooks
    Given I visit my project's settings page
    And I click the "Hooks" tab
    Then the active sub nav should be Hooks
    And no other sub navs should be active
    And the active main tab should be Settings

  Scenario: On Project Settings/Deploy Keys
    Given I visit my project's settings page
    And I click the "Deploy Keys" tab
    Then the active sub nav should be Deploy Keys
    And no other sub navs should be active
    And the active main tab should be Settings

  # Sub Tabs: Commits

  Scenario: On Project Commits/Commits
    Given I visit my project's commits page
    Then the active sub tab should be Commits
    And no other sub tabs should be active
    And the active main tab should be Commits

  Scenario: On Project Commits/Compare
    Given I visit my project's commits page
    And I click the "Compare" tab
    Then the active sub tab should be Compare
    And no other sub tabs should be active
    And the active main tab should be Commits

  Scenario: On Project Commits/Branches
    Given I visit my project's commits page
    And I click the "Branches" tab
    Then the active sub tab should be Branches
    And no other sub tabs should be active
    And the active main tab should be Commits

  Scenario: On Project Commits/Tags
    Given I visit my project's commits page
    And I click the "Tags" tab
    Then the active sub tab should be Tags
    And no other sub tabs should be active
    And the active main tab should be Commits

  # Sub Tabs: Issues

  Scenario: On Project Issues/Browse
    Given I visit my project's issues page
    Then the active sub tab should be Browse Issues
    And no other sub tabs should be active
    And the active main tab should be Issues

  Scenario: On Project Issues/Milestones
    Given I visit my project's issues page
    And I click the "Milestones" tab
    Then the active sub tab should be Milestones
    And no other sub tabs should be active
    And the active main tab should be Issues

  Scenario: On Project Issues/Labels
    Given I visit my project's issues page
    And I click the "Labels" tab
    Then the active sub tab should be Labels
    And no other sub tabs should be active
    And the active main tab should be Issues
