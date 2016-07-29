Feature: Project Pages
  Background:
    Given I sign in as a user
    And I own a project

  Scenario: Pages are disabled
    Given pages are disabled
    When I visit the Project Pages
    Then I should see that GitLab Pages are disabled

  Scenario: I can see the pages usage if not deployed
    Given pages are enabled
    When I visit the Project Pages
    Then I should see the usage of GitLab Pages

  Scenario: I can access the pages if deployed
    Given pages are enabled
    And pages are deployed
    When I visit the Project Pages
    Then I should be able to access the Pages

  Scenario: I should message that domains support is disabled
    Given pages are enabled
    And pages are deployed
    And support for external domains is disabled
    When I visit the Project Pages
    Then I should see that support for domains is disabled

  Scenario: I should see a new domain button
    Given pages are enabled
    And pages are exposed on external HTTP address
    When I visit the Project Pages
    And I should be able to add a New Domain

  Scenario: I should be able to add a new domain
    Given pages are enabled
    And pages are exposed on external HTTP address
    When I visit add a new Pages Domain
    And I fill the domain
    And I click on "Create New Domain"
    Then I should see a new domain added

  Scenario: I should be able to add a new domain for project in group namespace
    Given I own a project in some group namespace
    And pages are enabled
    And pages are exposed on external HTTP address
    When I visit add a new Pages Domain
    And I fill the domain
    And I click on "Create New Domain"
    Then I should see a new domain added

  Scenario: I should be denied to add the same domain twice
    Given pages are enabled
    And pages are exposed on external HTTP address
    And pages domain is added
    When I visit add a new Pages Domain
    And I fill the domain
    And I click on "Create New Domain"
    Then I should see error message that domain already exists

  Scenario: I should message that certificates support is disabled when trying to add a new domain
    Given pages are enabled
    And pages are exposed on external HTTP address
    And pages domain is added
    When I visit add a new Pages Domain
    Then I should see that support for certificates is disabled

  Scenario: I should be able to add a new domain with certificate
    Given pages are enabled
    And pages are exposed on external HTTPS address
    When I visit add a new Pages Domain
    And I fill the domain
    And I fill the certificate and key
    And I click on "Create New Domain"
    Then I should see a new domain added

  Scenario: I can remove the pages if deployed
    Given pages are enabled
    And pages are deployed
    When I visit the Project Pages
    And I click Remove Pages
    Then The Pages should get removed
