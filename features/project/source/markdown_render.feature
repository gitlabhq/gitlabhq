Feature: Project Source Markdown Render
  Background:
    Given I sign in as a user
    And I own project "Delta"
    And I visit markdown branch

  # Tree README

  Scenario: Tree view should have correct links in README
    Given I go directory which contains README file
    And I click on a relative link in README
    Then I should see the correct markdown

  Scenario: I browse files from markdown branch
    Then I should see files from repository in markdown
    And I should see rendered README which contains correct links
    And I click on Gitlab API in README
    Then I should see correct document rendered

  Scenario: I view README in markdown branch
    Then I should see files from repository in markdown
    And I should see rendered README which contains correct links
    And I click on Rake tasks in README
    Then I should see correct directory rendered

  Scenario: I view README in markdown branch to see reference links to directory
    Then I should see files from repository in markdown
    And I should see rendered README which contains correct links
    And I click on GitLab API doc directory in README
    Then I should see correct doc/api directory rendered

  Scenario: I view README in markdown branch to see reference links to file
    Then I should see files from repository in markdown
    And I should see rendered README which contains correct links
    And I click on Maintenance in README
    Then I should see correct maintenance file rendered

  Scenario: README headers should have header links
    Then I should see rendered README which contains correct links
    And Header "Application details" should have correct id and link

  # Blob

  Scenario: I navigate to doc directory to view documentation in markdown
    And I navigate to the doc/api/README
    And I see correct file rendered
    And I click on users in doc/api/README
    Then I should see the correct document file

  Scenario: I navigate to doc directory to view user doc in markdown
    And I navigate to the doc/api/README
    And I see correct file rendered
    And I click on raketasks in doc/api/README
    Then I should see correct directory rendered

  Scenario: I navigate to doc directory to view user doc in markdown
    And I navigate to the doc/api/README
    And Header "GitLab API" should have correct id and link

  # Markdown branch

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

  Scenario: Tree markdown links view empty urls should have correct urls
    When I visit markdown branch
    Then The link with text "empty" should have url "tree/markdown"
    When I visit markdown branch "README.md" blob
    Then The link with text "empty" should have url "blob/markdown/README.md"
    When I visit markdown branch "d" tree
    Then The link with text "empty" should have url "tree/markdown/d"
    When I visit markdown branch "d/README.md" blob
    Then The link with text "empty" should have url "blob/markdown/d/README.md"

  # "ID" means "#id" on the tests below, because we are unable to escape the hash sign.
  # which Spinach interprets as the start of a comment.
  Scenario: All markdown links with ids should have correct urls
    When I visit markdown branch
    Then The link with text "ID" should have url "tree/markdownID"
    Then The link with text "/ID" should have url "tree/markdownID"
    Then The link with text "README.mdID" should have url "blob/markdown/README.mdID"
    Then The link with text "d/README.mdID" should have url "blob/markdown/d/README.mdID"
    When I visit markdown branch "README.md" blob
    Then The link with text "ID" should have url "blob/markdown/README.mdID"
    Then The link with text "/ID" should have url "blob/markdown/README.mdID"
    Then The link with text "README.mdID" should have url "blob/markdown/README.mdID"
    Then The link with text "d/README.mdID" should have url "blob/markdown/d/README.mdID"

  # Wiki

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

  Scenario: Wiki headers should have should have ids generated for them.
    Given I go to wiki page
    And I add a header to the wiki page
    Then Wiki header should have correct id and link
