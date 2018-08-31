# JUnit test reports

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/45318) in GitLab 11.2.
Requires GitLab Runner 11.2 and above.

## Overview

It is very common that a [CI/CD pipeline](pipelines.md) contains a
test job that will verify your code.
If the tests fail, the pipeline fails and users get notified. The person that
works on the merge request will have to check the job logs and see where the
tests failed so that they can fix them.

You can configure your job to use JUnit test reports, and GitLab will display a
report on the merge request so that it's easier and faster to identify the
failure without having to check the entire log.

## Use cases

Consider the following workflow:

1. Your `master` branch is rock solid, your project is using GitLab CI/CD and
   your pipelines indicate that there isn't anything broken.
1. Someone from you team submits a merge request, a test fails and the pipeline
   gets the known red icon. To investigate more, you have to go through the job
   logs to figure out the cause of the failed test, which usually contain
   thousands of lines.
1. You configure the JUnit test reports and immediately GitLab collects and
   exposes them in the merge request. No more searching in the job logs.
1. Your development and debugging workflow becomes easier, faster and efficient.

## How it works

First, GitLab Runner uploads all JUnit XML files as artifacts to GitLab. Then,
when you visit a merge request, GitLab starts comparing the head and base branch's
JUnit test reports, where:

- The base branch is the target branch (usually `master`).
- The head branch is the source branch (the latest pipeline in each merge request).

The reports panel has a summary showing how many tests failed and how many were fixed.
If no comparison can be done because data for the base branch is not available,
the panel will just show the list of failed tests for head.

There are three types of results:

1. **Newly failed tests:** Test cases which passed on base branch and failed on head branch
1. **Existing failures:**  Test cases which failed on base branch and failed on head branch
1. **Resolved failures:**  Test cases which failed on base branch and passed on head branch

Each entry in the panel will show the test name and its type from the list
above. Clicking on the test name will open a modal window with details of its
execution time and the error output.

![Test Reports Widget](img/junit_test_report.png)

## How to set it up

NOTE: **Note:**
For a list of supported languages on JUnit tests, check the
[Wikipedia article](https://en.wikipedia.org/wiki/JUnit#Ports).

To enable the JUnit reports in merge requests, you need to add
[`artifacts:reports:junit`](yaml/README.md#artifacts-reports-junit)
in `.gitlab-ci.yml`, and specify the path(s) of the generated test reports.

In the following examples, the job in the `test` stage runs and GitLab
collects the JUnit test report from each job. After each job is executed, the
XML reports are stored in GitLab as artifacts and their results are shown in the
merge request widget.

### Ruby example

Use the following job in `.gitlab-ci.yml`:

```yaml
## Use https://github.com/sj26/rspec_junit_formatter to generate a JUnit report with rspec
ruby:
  stage: test
  script:
  - bundle install
  - rspec spec/lib/ --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
```

### Go example

Use the following job in `.gitlab-ci.yml`:

```yaml
## Use https://github.com/jstemmer/go-junit-report to generate a JUnit report with go
golang:
  stage: test
  script:
  - go get -u github.com/jstemmer/go-junit-report
  - go test -v 2>&1 | go-junit-report > report.xml
  artifacts:
    reports:
      junit: report.xml
```

### Java examples
#### Gradle

Use the following job in `.gitlab-ci.yml`:

```yaml
java:
  stage: test
  script:
  - gradle test
  artifacts:
    reports:
      junit: build/test-results/test/TEST-*.xml
```

If you define multiple tasks of kind test, it will generate multiple directories 
under `build/test-results/` directory. 
To address all subdirectory at once, you can leverage regex matching by defining following 
path: `build/test-results/test/TEST-*.xml`
