Feature: Project Merge Requests
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" have "Bug NS-04" open merge request
    And project "Shop" have "Feature NS-03" closed merge request
    And I visit project "Shop" merge requests page

  Scenario: I should see open merge requests
    Then I should see "Bug NS-04" in merge requests
    And I should not see "Feature NS-03" in merge requests

  Scenario: I should see closed merge requests
    Given I click link "Closed"
    Then I should see "Feature NS-03" in merge requests
    And I should not see "Bug NS-04" in merge requests

  Scenario: I should see all merge requests
    Given I click link "All"
    Then I should see "Feature NS-03" in merge requests
    And I should see "Bug NS-04" in merge requests

  Scenario: I visit merge request page
    Given I click link "Bug NS-04"
    Then I should see merge request "Bug NS-04"

  Scenario: I close merge request page
    Given I click link "Bug NS-04"
    And I click link "Close"
    Then I should see closed merge request "Bug NS-04"

  Scenario: I reopen merge request page
    Given I click link "Bug NS-04"
    And I click link "Close"
    Then I should see closed merge request "Bug NS-04"
    When I click link "Reopen"
    Then I should see reopened merge request "Bug NS-04"

  Scenario: I submit new unassigned merge request
    Given I click link "New Merge Request"
    And I submit new merge request "Wiki Feature"
    Then I should see merge request "Wiki Feature"

  @javascript
  Scenario: I comment on a merge request
    Given I visit merge request page "Bug NS-04"
    And I leave a comment like "XML attached"
    Then I should see comment "XML attached"

  @javascript
  Scenario: I comment on a merge request diff
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I switch to the diff tab
    And I leave a comment like "Line is wrong" on line 185 of the first file
    And I switch to the merge request's comments tab
    Then I should see a discussion has started on line 185

  @javascript
  Scenario: I comment on a line of a commit in merge request
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the first commit in the merge request
    And I leave a comment like "Line is wrong" on line 185 of the first file in commit
    And I switch to the merge request's comments tab
    Then I should see a discussion has started on commit b1e6a9dbf1:L185

  @javascript
  Scenario: I comment on a commit in merge request
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And I visit merge request page "Bug NS-05"
    And I click on the first commit in the merge request
    And I leave a comment on the diff page in commit
    And I switch to the merge request's comments tab
    Then I should see a discussion has started on commit b1e6a9dbf1

  @javascript
  Scenario: I accept merge request with custom commit message
    Given project "Shop" have "Bug NS-05" open merge request with diffs inside
    And merge request "Bug NS-05" is mergeable
    And I visit merge request page "Bug NS-05"
    And merge request is mergeable
    Then I modify merge commit message
    And I accept this merge request
    Then I should see merged request

  # Markdown

  Scenario: Headers inside the description should have ids generated for them.
    When I visit merge request page "Bug NS-04"
    Then Header "Description header" should have correct id and link

  @javascript
  Scenario: Headers inside comments should not have ids generated for them.
    Given I visit merge request page "Bug NS-04"
    And I leave a comment with a header containing "Comment with a header"
    Then The comment with the header should not have an ID
