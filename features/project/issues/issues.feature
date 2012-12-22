Feature: Project Issues
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" have "Release 0.4" open issue
    And project "Shop" have "Release 0.3" closed issue
    And I visit project "Shop" issues page

  Scenario: I should see open issues
    Given I should see "Release 0.4" in issues
    And I should not see "Release 0.3" in issues

  Scenario: I should see closed issues
    Given I click link "Closed"
    Then I should see "Release 0.3" in issues
    And I should not see "Release 0.4" in issues

  Scenario: I should see all issues
    Given I click link "All"
    Then I should see "Release 0.3" in issues
    And I should see "Release 0.4" in issues

  Scenario: I visit issue page
    Given I click link "Release 0.4"
    Then I should see issue "Release 0.4"

  Scenario: I submit new unassigned issue
    Given I click link "New Issue"
    And I submit new issue "500 error on profile"
    Then I should see issue "500 error on profile"

  @javascript
  Scenario: I comment issue
    Given I visit issue page "Release 0.4"
    And I leave a comment like "XML attached"
    Then I should see comment "XML attached"

  @javascript
  Scenario: I search issue
    Given I fill in issue search with "Release"
    Then I should see "Release 0.4" in issues
    And I should not see "Release 0.3" in issues

  @javascript
  Scenario: I search issue that not exist
    Given I fill in issue search with "Bug"
    Then I should not see "Release 0.4" in issues
    And I should not see "Release 0.3" in issues


  @javascript
  Scenario: I search all issues
    Given I click link "All"
    And I fill in issue search with "0.3"
    Then I should see "Release 0.3" in issues
    And I should not see "Release 0.4" in issues

  # Disable this two cause of random failing
  # TODO: fix after v4.0 released
  #@javascript
  #Scenario: I create Issue with pre-selected milestone
    #Given project "Shop" has milestone "v2.2"
    #And project "Shop" has milestone "v3.0"
    #And I visit project "Shop" issues page
    #When I select milestone "v3.0"
    #And I click link "New Issue"
    #Then I should see selected milestone with title "v3.0"

  #@javascript
  #Scenario: I create Issue with pre-selected assignee
    #When I select first assignee from "Shop" project
    #And I click link "New Issue"
    #Then I should see first assignee from "Shop" as selected assignee
