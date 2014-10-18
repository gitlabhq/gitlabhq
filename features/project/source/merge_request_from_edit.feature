Feature: Project Source Merge Request From Edit
  Background:
    Given I sign in as a user
    And I am a master of project "Shop"

  @javascript
  Scenario: I can create a merge request from the current project to itself
    Given I visit ".gitignore" file edit page
    And I edit code
    And I fill the commit message
    And I check "Create merge request"
    And I uncheck "On my fork"
    And I fill the new branch name
    And I click on "Commit changes"
    Then I should be redirected to the new merge request page from origin to itself

  @javascript @wip
  Scenario: I can create a merge request from an existing fork to the original project
    Given I have a project forked off of "Shop" called "Forked Shop"
    And I visit ".gitignore" file edit page
    And I edit code
    And I fill the commit message
    And I check "Create merge request"
    And I fill the new branch name
    And I click on "Commit changes"
    Then I should be redirected to the new merge request page from origin to fork

  @javascript @wip
  Scenario: I can create a merge request from a new fork to the original project
    Given I visit ".gitignore" file edit page
    And I edit code
    And I fill the commit message
    And I check "Create merge request"
    And I fill the new branch name
    And I click on "Commit changes"
    Then I should be redirected to the new merge request page from origin to fork

  @javascript
  Scenario: If the commit fails because of invalid input, then the editor content is kept
    Given I visit ".gitignore" file edit page
    And I edit code
    And I fill the commit message
    And I check "Create merge request"
    And I fill the new branch name with an invalid branch name
    And I click on "Commit changes"
    Then I should be on ".gitignore" file edit page
    And I should see the new edited content

  # Form interaction effects

  @javascript
  Scenario: If I don't click on "Create merge request", then I don't see the merge request options
    Given I visit ".gitignore" file edit page
    Then I don't see the "New branch name" input
    Given I check "Create merge request"
    Then I see the "New branch name" input

  @javascript
  Scenario: If I don't have push permission, then I must fork to create a merge request
    Given public project "Community"
    And I visit ".gitignore" file edit page of project "Community"
    Then "Create merge request" is checked and disabled
    And "On my fork" is checked and disabled

  @javascript
  Scenario: If I am on my namespace, then I cannot create a merge request on a fork
    Given I have a project forked off of "Shop" called "Forked Shop"
    And I visit ".gitignore" file edit page of project "Forked Shop"
    And I check "Create merge request"
    Then I don't see the "On my fork" checkbox

  @javascript
  Scenario: If I toggle "On my fork" before editing the branch name, it changes to a free branch name on my fork
    Given I have a project forked off of "Shop" called "Forked Shop"
    And Project "Shop" has a branch named "patch-1"
    And I visit ".gitignore" file edit page
    And I check "Create merge request"
    Then The new branch name is "patch-1"
    When I uncheck "On my fork"
    Then The new branch name is "patch-2"
    When I check "On my fork"
    Then The new branch name is "patch-1"

  @javascript
  Scenario: If I toggle "On my fork" after editing the branch name, it does not change
    Given I have a project forked off of "Shop" called "Forked Shop"
    And Project "Shop" has a branch named "patch-1"
    And I visit ".gitignore" file edit page
    And I check "Create merge request"
    And I fill the new branch name with a non-default value
    And I uncheck "On my fork"
    Then The new branch name is the non-default value

