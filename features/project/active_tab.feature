Feature: Project Active Tab
  Background:
    Given I sign in as a user
    And I own a project

  # Main Tabs

  Scenario: On Project Home
    Given I visit my project's home page
    Then the active sub tab should be Home
    And no other sub tabs should be active
    And the active main tab should be Project

  Scenario: On Project Repository
    Given I visit my project's files page
    Then the active main tab should be Repository
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

  Scenario: On Project Members
    Given I visit my project's members page
    Then the active main tab should be Members
    And no other main tabs should be active

  # Sub Tabs: Home

  Scenario: On Project Home/Show
    Given I visit my project's home page
    Then the active sub tab should be Home
    And no other sub tabs should be active
    And the active main tab should be Project
    And no other main tabs should be active

  Scenario: On Project Home/Activity
    Given I visit my project's home page
    And I click the "Activity" tab
    Then the active sub tab should be Activity
    And no other sub tabs should be active
    And the active main tab should be Project

  # Sub Tabs: Settings

  Scenario: On Project Settings/Integrations
    Given I visit my project's settings page
    And I click the "Integrations" tab
    Then the active sub tab should be Integrations
    And no other sub tabs should be active
    And the active main tab should be Settings

  Scenario: On Project Settings/Repository
    Given I visit my project's settings page
    And I click the "Repository" tab
    Then the active sub tab should be Repository
    And no other sub tabs should be active
    And the active main tab should be Settings

  # Sub Tabs: Repository

  Scenario: On Project Repository/Files
    Given I visit my project's files page
    Then the active sub tab should be Files
    And no other sub tabs should be active
    And the active main tab should be Repository

  Scenario: On Project Repository/Commits
    Given I visit my project's commits page
    Then the active sub tab should be Commits
    And no other sub tabs should be active
    And the active main tab should be Repository

  Scenario: On Project Repository/Graph
    Given I visit my project's graph page
    Then the active sub tab should be Graph
    And no other sub tabs should be active
    And the active main tab should be Repository

  Scenario: On Project Repository/Compare
    Given I visit my project's commits page
    And I click the "Compare" tab
    Then the active sub tab should be Compare
    And no other sub tabs should be active
    And the active main tab should be Repository

  Scenario: On Project Repository/Charts
    Given I visit my project's commits page
    And I click the "Charts" tab
    Then the active sub tab should be Charts
    And no other sub tabs should be active
    And the active main tab should be Repository

  Scenario: On Project Repository/Branches
    Given I visit my project's commits page
    And I click the "Branches" tab
    Then the active sub tab should be Branches
    And no other sub tabs should be active
    And the active main tab should be Repository

  Scenario: On Project Repository/Tags
    Given I visit my project's commits page
    And I click the "Tags" tab
    Then the active sub tab should be Tags
    And no other sub tabs should be active
    And the active main tab should be Repository

  Scenario: On Project Issues/Browse
    Given I visit my project's issues page
    Then the active main tab should be Issues
    And no other main tabs should be active

  Scenario: On Project Issues/Milestones
    Given I visit my project's issues page
    And I click the "Milestones" sub tab
    Then the active main tab should be Issues
    Then the active sub tab should be Milestones
    And no other main tabs should be active
    And no other sub tabs should be active

  Scenario: On Project Issues/Labels
    Given I visit my project's issues page
    And I click the "Labels" sub tab
    Then the active main tab should be Issues
    Then the active sub tab should be Labels
    And no other main tabs should be active
    And no other sub tabs should be active
