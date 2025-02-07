---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Unit test reports
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can configure your [CI/CD pipeline](../pipelines/_index.md) to display unit test results directly in merge requests and pipeline details.
This makes it easier to identify test failures without searching through job logs.

Unit test reports:

- Require the JUnit report format.
- Do not affect the job status. To make a job fail when unit tests fail, your job's [script](../yaml/_index.md#script) must exit with a non-zero status.

Consider the following workflow:

1. Your default branch is rock solid, your project is using GitLab CI/CD and
   your pipelines indicate that there isn't anything broken.
1. Someone from your team submits a merge request, a test fails and the pipeline
   gets the known red icon. To investigate more, you have to go through the job
   logs to figure out the cause of the failed test, which usually contain
   thousands of lines.
1. You configure the Unit test reports and immediately GitLab collects and
   exposes them in the merge request. No more searching in the job logs.
1. Your development and debugging workflow becomes easier, faster and efficient.

## How it works

First, GitLab Runner uploads all [JUnit report format XML files](https://www.ibm.com/docs/en/developer-for-zos/16.0?topic=formats-junit-xml-format)
as [artifacts](../yaml/artifacts_reports.md#artifactsreportsjunit) to GitLab. Then, when you visit a merge request, GitLab starts
comparing the head and base branch's JUnit report format XML files, where:

- The base branch is the target branch (usually the default branch).
- The head branch is the source branch (the latest pipeline in each merge request).

The **Test summary** panel shows how many tests failed, how many had errors,
and how many were fixed. If no comparison can be done because data for the base branch
is not available, the panel shows only the list of failed tests for the source branch.

The types of results are:

- **Newly failed tests:** Test cases which passed on the base branch and failed on the head branch.
- **Newly encountered errors:** Test cases which passed on the base branch and failed due to a
  test error on the head branch.
- **Existing failures:** Test cases which failed on the base branch and failed on the head branch.
- **Resolved failures:** Test cases which failed on the base branch and passed on the head branch.

### View failed tests

Each entry in the **Test summary** panel shows the test name and result type.
Select the test name to open a modal window with details of its execution time and
the error output.

![Test Reports Widget](img/junit_test_report_v13_9.png)

#### Copy failed test names

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91552) in GitLab 15.2.

You can copy the name and path of failed tests when there are failed tests listed
in the **Test summary** panel. Use name and path to find and rerun the
test locally for verification.

To copy the name of all failed tests, at the top of the **Test summary** panel,
select **Copy failed tests**. The failed tests are listed as a string with the tests
separated by spaces. This option is only available if the JUnit report populates
the `<file>` attributes for failed tests.

To copy the name of a single failed test:

1. Expand the **Test summary** panel by selecting **Show test summary details** (**{chevron-lg-down}**).
1. Select the test you want to review.
1. Select **Copy test name to rerun locally** (**{copy-to-clipboard}**).

### Number of recent failures

If a test failed in the project's default branch in the last 14 days, a message like
`Failed {n} time(s) in {default_branch} in the last 14 days` is displayed for that test.

The calculation includes failed tests in completed pipelines, but not [blocked pipelines](../jobs/job_control.md#types-of-manual-jobs).
[Issue 431265](https://gitlab.com/gitlab-org/gitlab/-/issues/431265) proposes to
also include blocked pipelines in the calculation.

## How to set it up

To enable the Unit test reports in merge requests, you must add
[`artifacts:reports:junit`](../yaml/artifacts_reports.md#artifactsreportsjunit)
in `.gitlab-ci.yml`, and specify the paths of the generated test reports.
The reports must be `.xml` files, otherwise [GitLab returns an Error 500](https://gitlab.com/gitlab-org/gitlab/-/issues/216575).

In the following example for Ruby, the job in the `test` stage runs and GitLab
collects the unit test report from the job. After the job is executed, the
XML report is stored in GitLab as an artifact, and the results are shown in the
merge request widget.

```yaml
## Use https://github.com/sj26/rspec_junit_formatter to generate a JUnit report format XML file with rspec
ruby:
  stage: test
  script:
    - bundle install
    - bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml
  artifacts:
    when: always
    paths:
      - rspec.xml
    reports:
      junit: rspec.xml
```

To make the Unit test report output files browsable, include them with the
[`artifacts:paths`](../yaml/_index.md#artifactspaths) keyword as well, as shown in the example.
To upload the report even if the job fails (for example if the tests do not pass),
use the [`artifacts:when:always`](../yaml/_index.md#artifactswhen) keyword.

You cannot have multiple tests with the same name and class in your JUnit report format XML file.

In GitLab 15.0 and earlier, test reports from [parallel:matrix](../yaml/_index.md#parallelmatrix)
jobs are aggregated together, which can cause some report information to not be displayed.
In GitLab 15.1 and later, [this bug is fixed](https://gitlab.com/gitlab-org/gitlab/-/issues/296814),
and all report information is displayed.

## View Unit test reports on GitLab

If JUnit report format XML files are generated and uploaded as part of a pipeline, these reports
can be viewed inside the pipelines details page. The **Tests** tab on this page
displays a list of test suites and cases reported from the XML file.

![Test Reports Widget](img/pipelines_junit_test_report_v13_10.png)

You can view all the known test suites and select each of these to see further
details, including the cases that make up the suite.

You can also retrieve the reports via the [GitLab API](../../api/pipelines.md#get-a-pipelines-test-report).

### Unit test reports parsing errors

If parsing JUnit report XML results in an error, an indicator is shown next to the job name. Hovering over the icon shows the parser error in a tooltip. If multiple parsing errors come from [grouped jobs](../jobs/_index.md#group-similar-jobs-together-in-pipeline-views), GitLab shows only the first error from the group.

![Test Reports With Errors](img/pipelines_junit_test_report_with_errors_v13_10.png)

For test case parsing limits, see [Max test cases per unit test report](../../user/gitlab_com/_index.md#gitlab-cicd).

GitLab does not parse very [large nodes](https://nokogiri.org/tutorials/parsing_an_html_xml_document.html#parse-options) of JUnit reports. There is [an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/268035) open to make this optional.

## View JUnit screenshots on GitLab

You can upload your screenshots as [artifacts](../yaml/artifacts_reports.md#artifactsreportsjunit) to GitLab.
If JUnit report format XML files contain an `attachment` tag, GitLab parses the attachment.
When uploading screenshot artifacts:

- The `attachment` tags **must** contain the paths of the screenshots you uploaded relative to `$CI_PROJECT_DIR`. For
  example:

  ```xml
  <testcase time="1.00" name="Test">
    <system-out>[[ATTACHMENT|/path/to/some/file]]</system-out>
  </testcase>
  ```

- You should set the job that uploads the screenshot to
  [`artifacts:when: always`](../yaml/_index.md#artifactswhen) so that it still uploads a screenshot
  when a test fails.

After the attachment is uploaded, [the pipeline test report](#view-unit-test-reports-on-gitlab)
contains a link to the screenshot, for example:

![A failed unit test report with test details and screenshot attachment](img/unit_test_report_screenshot_v13_12.png)

## Troubleshooting

### Test report appears empty

When you view a unit test report in a merge request, it might appear empty for these reasons:

1. The artifact containing the report has expired. To resolve this issue, you can either:
   - Set a longer [`expire_in`](../yaml/_index.md#artifactsexpire_in) value for the report artifact.
   - Run a new pipeline to generate a new report.

1. The JUnit files exceed size limits. To resolve this issue:
   - Ensure individual JUnit files are less than 30 MB.
   - Ensure the total JUnit size for the job is less than 100 MB.

   Support for custom limits is proposed [epic 16374](https://gitlab.com/groups/gitlab-org/-/epics/16374).
