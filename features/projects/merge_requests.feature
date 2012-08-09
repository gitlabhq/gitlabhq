Feature: Merge Requests
  Background:
    Given I signin as a user
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

  Scenario: I submit new unassigned merge request
    Given I click link "New Merge Request"
    And I submit new merge request "Wiki Feature"
    Then I should see merge request "Wiki Feature"

  @javascript
  Scenario: I comment merge request
    Given I visit merge request page "Bug NS-04"
    And I leave a comment like "XML attached"
    Then I should see comment "XML attached"

