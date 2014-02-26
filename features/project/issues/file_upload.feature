Feature: Project Issue File Upload
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And project "Shop" have "Release 0.4" open issue
    And I visit issue page "Release 0.4"

  Scenario: I should see attachment button
    And I click link "Edit"
    Then I should see button "Choose File ..."

  Scenario: I can add and see filename in description
    And I click link "Edit"
    And I attach file "test_ss.ods"
    And I click button "Save changes"
    Then I should see link "test_ss.ods"

  Scenario: I should see filename in edit form
    And issue "Release 0.4" has attachment "test_ss.ods"
    And I click link "Edit"
    Then I should see link "test_ss.ods"

  Scenario: I can add and see image in description
    And I click link "Edit"
    And I attach image "insane-senior.jpg"
    And I click button "Save changes"
    Then I should see image "insane-senior.jpg"

  Scenario: I should see image in edit form
    And issue "Release 0.4" has attachment "insane-senior.jpg"
    And I click link "Edit"
    Then I should see image "insane-senior.jpg"

  @javascript
  Scenario: I delete attachment
    And issue "Release 0.4" has attachment "test_ss.ods"
    And I click link "Edit"
    And I click link "Delete"
    And I visit issue page "Release 0.4"
    Then I should not see link "test_ss.ods"
