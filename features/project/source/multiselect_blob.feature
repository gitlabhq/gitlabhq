Feature: Project Multiselect Blob
  Background:
    Given I sign in as a user
    And I own project "Shop"
    And I visit "Gemfile.lock" file in repo

  @javascript
  Scenario: I click line 1 in file
    When I click line 1 in file
    Then I should see "L1" as URI fragment
    And I should see line 1 highlighted

  @javascript
  Scenario: I shift-click line 1 in file
    When I shift-click line 1 in file
    Then I should see "L1" as URI fragment
    And I should see line 1 highlighted

  @javascript
  Scenario: I click line 1 then click line 2 in file
    When I click line 1 in file
    Then I should see "L1" as URI fragment
    And I should see line 1 highlighted
    Then I click line 2 in file
    Then I should see "L2" as URI fragment
    And I should see line 2 highlighted

  @javascript
  Scenario: I click various line numbers to test multiselect
    Then I click line 1 in file
    Then I should see "L1" as URI fragment
    And I should see line 1 highlighted
    Then I shift-click line 2 in file
    Then I should see "L1-2" as URI fragment
    And I should see lines 1-2 highlighted
    Then I shift-click line 3 in file
    Then I should see "L1-3" as URI fragment
    And I should see lines 1-3 highlighted
    Then I click line 3 in file
    Then I should see "L3" as URI fragment
    And I should see line 3 highlighted
    Then I shift-click line 1 in file
    Then I should see "L1-3" as URI fragment
    And I should see lines 1-3 highlighted
    Then I shift-click line 5 in file
    Then I should see "L1-5" as URI fragment
    And I should see lines 1-5 highlighted
    Then I shift-click line 4 in file
    Then I should see "L1-4" as URI fragment
    And I should see lines 1-4 highlighted
    Then I click line 5 in file
    Then I should see "L5" as URI fragment
    And I should see line 5 highlighted
    Then I shift-click line 3 in file
    Then I should see "L3-5" as URI fragment
    And I should see lines 3-5 highlighted
    Then I shift-click line 1 in file
    Then I should see "L1-3" as URI fragment
    And I should see lines 1-3 highlighted
    Then I shift-click line 1 in file
    Then I should see "L1" as URI fragment
    And I should see line 1 highlighted

  @javascript
  Scenario: I multiselect lines 1-5 and then go back and forward in history
    When I click line 1 in file
    And I shift-click line 3 in file
    And I shift-click line 2 in file
    And I shift-click line 5 in file
    Then I should see "L1-5" as URI fragment
    And I should see lines 1-5 highlighted
    Then I go back in history
    Then I should see "L1-2" as URI fragment
    And I should see lines 1-2 highlighted
    Then I go back in history
    Then I should see "L1-3" as URI fragment
    And I should see lines 1-3 highlighted
    Then I go back in history
    Then I should see "L1" as URI fragment
    And I should see line 1 highlighted
    Then I go forward in history
    And I go forward in history
    And I go forward in history
    Then I should see "L1-5" as URI fragment
    And I should see lines 1-5 highlighted
