# Test Plan

<!-- This issue outlines testing activities related to a particular issue or epic.

[Here is an example test plan](https://gitlab.com/gitlab-org/gitlab-foss/issues/50353)

This and other comments should be removed as you write the plan -->

## Introduction

<!-- Briefly outline what is being tested

Mention the issue(s) this test plan is related to -->

## Scope

<!-- State any limits on aspects of the feature being tested
Outline the types of data to be included
Outline the types of tests to be performed (functional, security, performance,
database, automated, etc) -->

## ACC Matrix

<!-- Use the matrix below as a template to identify the Attributes, Components, and
Capabilities relevant to the scope of this test plan. Add or remove Attributes
and Components as required and list Capabilities in the next section

Attributes (columns) are adverbs or adjectives that describe (at a high level)
the qualities testing is meant to ensure Components have.

Components (rows) are nouns that define major parts of the product being tested.

Capabilities link Attributes and Components. They are what your product needs to
do to make sure a Component fulfills an Attribute

For more information see the [Google Testing Blog article about the 10 minute
test plan](https://testing.googleblog.com/2011/09/10-minute-test-plan.html) and
[this wiki page from an open-source tool that implements the ACC
model](https://code.google.com/archive/p/test-analytics/wikis/AccExplained.wiki). -->

|            | Secure | Responsive | Intuitive | Reliable |
|------------|:------:|:----------:|:---------:|:--------:|
| Admin      |        |            |           |          |
| Groups     |        |            |           |          |
| Project    |        |            |           |          |
| Repository |        |            |           |          |
| Issues     |        |            |           |          |
| MRs        |        |            |           |          |
| CI/CD      |        |            |           |          |
| Ops        |        |            |           |          |
| Registry   |        |            |           |          |
| Wiki       |        |            |           |          |
| Snippets   |        |            |           |          |
| Settings   |        |            |           |          |
| Tracking   |        |            |           |          |
| API        |        |            |           |          |

## Capabilities

<!-- Use the ACC matrix above to help you identify Capabilities at each relevant
intersection of Components and Attributes.

Some features might be simple enough that they only involve one Component, while
more complex features could involve multiple or even all.

Example (from https://gitlab.com/gitlab-org/gitlab-foss/issues/50353):
* Repository is
  * Intuitive
    * It's easy to select the desired file template
    * It doesn't require unnecessary actions to save the change
    * It's easy to undo the change after selecting a template
  * Responsive
    * The list of templates can be restricted to allow a user to find a specific template among many
    * Once a template is selected the file content updates quickly and smoothly
-->

## Test Plan

<!-- If the scope is small enough you may not need to write a list of tests to
perform. It might be enough to use the Capabilities to guide your testing.

If the feature is more complex, especially if it involves multiple Components,
briefly outline a set of tests here. When identifying tests to perform be sure
to consider risk. Note inherent/known levels of risk so that testing can focus
on high risk areas first.

New end-to-end and integration tests (Selenium and API) should be added to the
[Test Coverage sheet](https://docs.google.com/spreadsheets/d/1RlLfXGboJmNVIPP9jgFV5sXIACGfdcFq1tKd7xnlb74/)

Please note if automated tests already exist.

When adding new automated tests, please keep [testing levels](https://docs.gitlab.com/ee/development/testing_guide/testing_levels.html)
in mind.
-->

/label ~Quality ~"test\-plan"
