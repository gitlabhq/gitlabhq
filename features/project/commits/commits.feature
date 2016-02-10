@project_commits
Feature: Project Commits
  Background:
    Given I sign in as a user
    And I own a project
    And I visit my project's commits page

  Scenario: I browse commits list for master branch
    Then I see project commits
    And I should not see button to create a new merge request
    Then I click the "Compare" tab
    And I should not see button to create a new merge request

  Scenario: I browse commits list for feature branch without a merge request
    Given I visit commits list page for feature branch
    Then I see feature branch commits
    And I see button to create a new merge request
    Then I click the "Compare" tab
    And I see button to create a new merge request

  Scenario: I browse commits list for feature branch with an open merge request
    Given project have an open merge request
    And I visit commits list page for feature branch
    Then I see feature branch commits
    And I should not see button to create a new merge request
    And I should see button to the merge request
    Then I click the "Compare" tab
    And I should not see button to create a new merge request
    And I should see button to the merge request

  Scenario: I browse atom feed of commits list for master branch
    Given I click atom feed link
    Then I see commits atom feed

  Scenario: I browse commit from list
    Given I click on commit link
    Then I see commit info
    And I see side-by-side diff button

  Scenario: I browse commit with ci from list
    Given commit has ci status
    And repository contains ".gitlab-ci.yml" file
    When I click on commit link
    Then I see commit ci info
    And I click status link
    Then I see builds list

  Scenario: I browse commit with side-by-side diff view
    Given I click on commit link
    And I click side-by-side diff button
    Then I see inline diff button

  @javascript
  Scenario: I compare branches without a merge request
    Given I visit compare refs page
    And I fill compare fields with branches
    Then I see compared branches
    And I see button to create a new merge request

  @javascript
  Scenario: I compare branches with an open merge request
    Given project have an open merge request
    And I visit compare refs page
    And I fill compare fields with branches
    Then I see compared branches
    And I should not see button to create a new merge request
    And I should see button to the merge request

  @javascript
  Scenario: I compare refs
    Given I visit compare refs page
    And I fill compare fields with refs
    Then I see compared refs
    And I unfold diff
    Then I should see additional file lines

  Scenario: I browse commits for a specific path
    Given I visit my project's commits page for a specific path
    Then I see breadcrumb links

  # TODO: Implement feature in graphs
  #Scenario: I browse commits stats
    #Given I visit my project's commits stats page
    #Then I see commits stats

  Scenario: I browse big commit
    Given I visit big commit page
    Then I see big commit warning
    And I see "Reload with full diff" link

  Scenario: I browse a commit with an image
    Given I visit a commit with an image that changed
    Then The diff links to both the previous and current image

  @javascript
  Scenario: I filter commits by message
    When I search "submodules" commits
    Then I should see only "submodules" commits
