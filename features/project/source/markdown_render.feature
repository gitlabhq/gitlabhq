Feature: Project markdown render
  Background:
    Given I sign in as a user
    And I own project "Delta"
    Given I visit project source page

  Scenario: I browse files from master branch
    Then I should see files from repository in master
    And I should see rendered README which contains correct links
    And I click on Gitlab API in README
    Then I should see correct document rendered

  Scenario: I view README in master branch
    Then I should see files from repository in master
    And I should see rendered README which contains correct links
    And I click on Rake tasks in README
    Then I should see correct directory rendered

  Scenario: I navigate to doc directory to view documentation in master
    And I navigate to the doc/api/README
    And I see correct file rendered
    And I click on users in doc/api/README
    Then I should see the correct document file

  Scenario: I navigate to doc directory to view user doc in master
    And I navigate to the doc/api/README
    And I see correct file rendered
    And I click on raketasks in doc/api/README
    Then I should see correct directory rendered

  Scenario: I browse files from markdown branch
    When I visit markdown branch
    Then I should see files from repository in markdown branch
    And I should see rendered README which contains correct links
    And I click on Gitlab API in README
    Then I should see correct document rendered for markdown branch

  Scenario: I browse directory from markdown branch
    When I visit markdown branch
    Then I should see files from repository in markdown branch
    And I should see rendered README which contains correct links
    And I click on Rake tasks in README
    Then I should see correct directory rendered for markdown branch

  Scenario: I navigate to doc directory to view documentation in markdown branch
    When I visit markdown branch
    And I navigate to the doc/api/README
    And I see correct file rendered in markdown branch
    And I click on users in doc/api/README
    Then I should see the users document file in markdown branch

  Scenario: I navigate to doc directory to view user doc in markdown branch
    When I visit markdown branch
    And I navigate to the doc/api/README
    And I see correct file rendered in markdown branch
    And I click on raketasks in doc/api/README
    Then I should see correct directory rendered for markdown branch

  Scenario: I create a wiki page with different links
    Given I go to wiki page
    And I add various links to the wiki page
    Then Wiki page should have added links
    And I click on test link
    Then I see new wiki page named test
    When I go back to wiki page home
    And I click on GitLab API doc link
    Then I see Gitlab API document
    When I go back to wiki page home
    And I click on Rake tasks link
    Then I see Rake tasks directory

  Scenario: I visit the help page with markdown
    Given I visit to the help page
    And I select a page with markdown
    Then I should see a help page with markdown

  Scenario: Tree view should have correct links in README
    Given I go directory which contains README file
    And I click on a relative link in README
    Then I should see the correct markdown
