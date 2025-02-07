---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Code Quality
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Code Quality helps code authors find and fix problems faster, and frees up time for code reviewers to focus their attention on more nuanced suggestions or comments.

When you use Code Quality in your CI/CD pipelines, you can avoid merging changes that would degrade your code's quality or deviate from your organization's standards.

## Features per tier

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/),
as shown in the following table:

| Feature                                                                                     | In Free                | In Premium             | In Ultimate            |
|:--------------------------------------------------------------------------------------------|:-----------------------|:-----------------------|:-----------------------|
| [Import Code Quality results from CI/CD jobs](#import-code-quality-results-from-a-cicd-job) | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| [Use CodeClimate-based scanning](#use-the-built-in-code-quality-cicd-template-deprecated)   | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| [See findings in a merge request widget](#merge-request-widget)                             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| [See findings in a pipeline report](#pipeline-details-view)                                 | **{dotted-circle}** No | **{check-circle}** Yes | **{check-circle}** Yes |
| [See findings in the merge request changes view](#merge-request-changes-view)               | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes |
| [Analyze overall health in a project quality summary view](#project-quality-view)           | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes |

## Scan code for quality violations

Code Quality is an open system that supports importing results from many scanning tools.
To find violations and surface them, you can:

- Directly use a scanning tool and [import its results](#import-code-quality-results-from-a-cicd-job). _(Preferred.)_
- [Use a built-in CI/CD template](#use-the-built-in-code-quality-cicd-template-deprecated) to enable scanning. The template uses the CodeClimate engine, which wraps common open source tools. _(Deprecated.)_

You can capture results from multiple tools in a single pipeline.
For example, you can run a code linter to scan your code along with a language linter to scan your documentation, or you can use a standalone tool along with CodeClimate-based scanning.
Code Quality combines all of the reports so you see all of them when you [view results](#view-code-quality-results).

### Import Code Quality results from a CI/CD job

Many development teams already use linters, style checkers, or other tools in their CI/CD pipelines to automatically detect violations of coding standards.
You can make the findings from these tools easier to see and fix by integrating them with Code Quality.

To see if your tool already has a documented integration, see [Integrate common tools with Code Quality](#integrate-common-tools-with-code-quality).

To integrate a different tool with Code Quality:

1. Add the tool to your CI/CD pipeline.
1. Configure the tool to output a report as a file.
   - This file must use a [specific JSON format](#code-quality-report-format).
   - Many tools support this output format natively. They may call it a "CodeClimate report", "GitLab Code Quality report", or another similar name.
   - Other tools can sometimes create JSON output using a custom JSON format or template. Because the [report format](#code-quality-report-format) has only a few required fields, you may be able to use this output type to create a report for Code Quality.
1. Declare a [`codequality` report artifact](../yaml/artifacts_reports.md#artifactsreportscodequality) that matches this file.

Now, after the pipeline runs, the quality tool's results are [processed and displayed](#view-code-quality-results).

### Use the built-in Code Quality CI/CD template (deprecated)

WARNING:
This feature was [deprecated](../../update/deprecations.md#codeclimate-based-code-quality-scanning-will-be-removed) in GitLab 17.3 and is planned for removal in 18.0.
[Integrate the results from a supported tool directly](#import-code-quality-results-from-a-cicd-job) instead.

Code Quality also includes a built-in CI/CD template, `Code-Quality.gitlab-ci.yaml`.
This template runs a scan based on the open source CodeClimate scanning engine.

The CodeClimate engine runs:

- Basic maintainability checks for a [set of supported languages](https://docs.codeclimate.com/docs/supported-languages-for-maintainability).
- A configurable set of [plugins](https://docs.codeclimate.com/docs/list-of-engines), which wrap open source scanners, to analyze your source code.

For more details, see [Configure CodeClimate-based Code Quality scanning](code_quality_codeclimate_scanning.md).

#### Migrate from CodeClimate-based scanning

The CodeClimate engine uses a customizable set of [analysis plugins](code_quality_codeclimate_scanning.md#configure-codeclimate-analysis-plugins).
Some are on by default; others must be explicitly enabled.
The following integrations are available to replace the built-in plugins:

| Plugin       | On by default                                | Replacement                                                                                                                                                                          |
|--------------|----------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Duplication  | **{check-circle}** Yes                       | [Integrate PMD Copy/Paste Detector](#pmd-copypaste-detector).                                                                                                                        |
| ESLint       | **{check-circle}** Yes                       | [Integrate ESLint](#eslint).                                                                                                                                                         |
| gofmt        | **{dotted-circle}** No                       | [Integrate golangci-lint](#golangci-lint) and enable the [gofmt linter](https://golangci-lint.run/usage/linters#gofmt).                                                              |
| golint       | **{dotted-circle}** No                       | [Integrate golangci-lint](#golangci-lint) and enable one of the included linters that replaces golint. golint is [deprecated and frozen](https://github.com/golang/go/issues/38968). |
| govet        | **{dotted-circle}** No                       | [Integrate golangci-lint](#golangci-lint). golangci-lint [includes govet by default](https://golangci-lint.run/usage/linters#enabled-by-default).                                    |
| markdownlint | **{dotted-circle}** No (community-supported) | [Integrate markdownlint-cli2](#markdownlint-cli2).                                                                                                                                   |
| pep8         | **{dotted-circle}** No                       | Integrate an alternative Python linter like [Flake8](#flake8), [Pylint](#pylint), or [Ruff](#ruff).                                                                                  |
| RuboCop      | **{dotted-circle}** Yes                      | [Integrate RuboCop](#rubocop).                                                                               |
| SonarPython  | **{dotted-circle}** No                       | Integrate an alternative Python linter like [Flake8](#flake8), [Pylint](#pylint), or [Ruff](#ruff).                                                                                  |
| Stylelint    | **{dotted-circle}** No (community-supported) | [Integrate Stylelint](#stylelint).                                                                                                                                                   |
| SwiftLint    | **{dotted-circle}** No                       | [Integrate SwiftLint](#swiftlint).                                                                                                                                                   |

## View Code Quality results

Code Quality results are shown in the:

- [Merge request widget](#merge-request-widget)
- [Merge request changes view](#merge-request-changes-view)
- [Pipeline details view](#pipeline-details-view)
- [Project quality view](#project-quality-view)

### Merge request widget

Code Quality analysis results display in the merge request widget area if a report from the target
branch is available for comparison. The merge request widget displays Code Quality findings and resolutions that
were introduced by the changes made in the merge request. Multiple Code Quality findings with identical
fingerprints display as a single entry in the merge request widget. Each individual finding is available in the
full report available in the **Pipeline** details view.

![Code Quality Widget](img/code_quality_widget_v13_11.png)

### Merge request changes view

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Code Quality results display in the merge request **Changes** view. Lines containing Code Quality
issues are marked by a symbol beside the gutter. Select the symbol to see the list of issues, then select an issue to see its details.

![Code Quality Inline Indicator](img/code_quality_inline_indicator_v16_7.png)

### Pipeline details view

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The full list of Code Quality violations generated by a pipeline is shown in the **Code Quality**
tab of the pipeline's details page. The pipeline details view displays all Code Quality findings
that were found on the branch it was run on.

![Code Quality Report](img/code_quality_report_v13_11.png)

### Project quality view

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72724) in GitLab 14.5 [with a flag](../../administration/feature_flags.md) named `project_quality_summary_page`. This feature is in [beta](../../policy/development_stages_support.md). Disabled by default.

The project quality view displays an overview of the code quality findings. The view can be found under **Analyze > CI/CD analytics**, and requires [`project_quality_summary_page`](../../user/feature_flags.md) feature flag to be enabled for this particular project.

![Code Quality Summary](img/code_quality_summary_v15_9.png)

## Code Quality report format

You can [import Code Quality results](#import-code-quality-results-from-a-cicd-job) from any tool that can output a report in the following format.
This format is a version of the [CodeClimate report format](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types) that includes a smaller number of fields.

The file you provide as [Code Quality report artifact](../yaml/artifacts_reports.md#artifactsreportscodequality) must contain a single JSON array.
Each object in that array must have at least the following properties:

| Name                                                      | Description                                                                                            | Type                                                                         |
|-----------------------------------------------------------|--------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| `description`                                             | A human-readable description of the code quality violation.                                            | String                                                                       |
| `check_name`                                              | A unique name representing the check, or rule, associated with this violation.                         | String                                                                       |
| `fingerprint`                                             | A unique fingerprint to identify this specific code quality violation, such as a hash of its contents. | String                                                                       |
| `severity`                                                | The severity of the violation.                                                                         | String. Valid values are `info`, `minor`, `major`, `critical`, or `blocker`. |
| `location.path`                                           | The file containing the code quality violation, expressed as a relative path in the repository.        | String                                                                       |
| `location.lines.begin` or `location.positions.begin.line` | The line on which the code quality violation occurred.                                                 | Integer                                                                      |

The format is different from the [CodeClimate report format](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types) in the following ways:

- Although the [CodeClimate report format](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types) supports more properties, Code Quality only processes the fields listed above.
- The GitLab parser does not allow a [byte order mark](https://en.wikipedia.org/wiki/Byte_order_mark) at the beginning of the file.

For example, this is a compliant report:

```json
[
  {
    "description": "'unused' is assigned a value but never used.",
    "check_name": "no-unused-vars",
    "fingerprint": "7815696ecbf1c96e6894b779456d330e",
    "severity": "minor",
    "location": {
      "path": "lib/index.js",
      "lines": {
        "begin": 42
      }
    }
  }
]
```

## Integrate common tools with Code Quality

Many tools natively support the required [report format](#code-quality-report-format) to integrate their results with Code Quality.
They may call it a "CodeClimate report", "GitLab Code Quality report", or another similar name.

Other tools can be configured to create JSON output by providing a custom template or format specification.
Because the [report format](#code-quality-report-format) has only a few required fields, you may be able to use this output type to create a report for Code Quality.

If you already use a tool in your CI/CD pipeline, you should adapt the existing job to add a Code Quality report.
Adapting the existing job prevents you from running a separate job that may confuse developers and make your pipelines take longer to run.

If you don't already use a tool, you can write a CI/CD job from scratch or adopt the tool by using a component from [the CI/CD Catalog](../components/_index.md#cicd-catalog).

### Code scanning tools

#### ESLint

If you already have an [ESLint](https://eslint.org/) job in your CI/CD pipelines, you should add a report to send its output to Code Quality.
To integrate its output:

1. Add [`eslint-formatter-gitlab`](https://www.npmjs.com/package/eslint-formatter-gitlab) as a development dependency in your project.
1. Add the `--format gitlab` option to the command you use to run ESLint.
1. Declare a [`codequality` report artifact](../yaml/artifacts_reports.md#artifactsreportscodequality) that points to the location of the report file.
   - By default, the formatter reads your CI/CD configuration and infers the filename where it should save the report.
     If the formatter can't infer the filename you used in your artifact declaration, set the CI/CD variable `ESLINT_CODE_QUALITY_REPORT` to the filename specified for your artifact, such as `gl-code-quality-report.json`.

You can also use or adapt the [ESLint CI/CD component](https://gitlab.com/explore/catalog/eakca1/codequality-os-scanners-integration) to run the scan and integrate its output with Code Quality.

#### Stylelint

If you already have a [Stylelint](https://stylelint.io/) job in your CI/CD pipelines, you should add a report to send its output to Code Quality.
To integrate its output:

1. Add [`@studiometa/stylelint-formatter-gitlab`](https://www.npmjs.com/package/@studiometa/stylelint-formatter-gitlab) as a development dependency in your project.
1. Add the `--custom-formatter=@studiometa/stylelint-formatter-gitlab` option to the command you use to run Stylelint.
1. Declare a [`codequality` report artifact](../yaml/artifacts_reports.md#artifactsreportscodequality) that points to the location of the report file.
   - By default, the formatter reads your CI/CD configuration and infers the filename where it should save the report.
     If the formatter can't infer the filename you used in your artifact declaration, set the CI/CD variable `STYLELINT_CODE_QUALITY_REPORT` to the filename specified for your artifact, such as `gl-code-quality-report.json`.

For more details and an example CI/CD job definition, see the [documentation for `@studiometa/stylelint-formatter-gitlab`](https://www.npmjs.com/package/@studiometa/stylelint-formatter-gitlab#usage).

#### MyPy

If you already have a [MyPy](https://mypy-lang.org/) job in your CI/CD pipelines, you should add a report to send its output to Code Quality.
To integrate its output:

1. Install [`mypy-gitlab-code-quality`](https://pypi.org/project/mypy-gitlab-code-quality/) as a dependency in your project.
1. Change your `mypy` command to send its output to a file.
1. Add a step to your job `script` to reprocess the file into the required format by using `mypy-gitlab-code-quality`. For example:

   ```yaml
   - mypy $(find -type f -name "*.py" ! -path "**/.venv/**") --no-error-summary > mypy-out.txt || true  # "|| true" is used for preventing job failure when mypy find errors
   - mypy-gitlab-code-quality < mypy-out.txt > gl-code-quality-report.json
   ```

1. Declare a [`codequality` report artifact](../yaml/artifacts_reports.md#artifactsreportscodequality) that points to the location of the report file.

You can also use or adapt the [MyPy CI/CD component](https://gitlab.com/explore/catalog/eakca1/codequality-os-scanners-integration) to run the scan and integrate its output with Code Quality.

#### Flake8

If you already have a [Flake8](https://flake8.pycqa.org/) job in your CI/CD pipelines, you should add a report to send its output to Code Quality.
To integrate its output:

1. Install [`flake8-gl-codeclimate`](https://github.com/awelzel/flake8-gl-codeclimate) as a dependency in your project.
1. Add the arguments `--format gl-codeclimate --output-file gl-code-quality-report.json` to the command you use to run Flake8.
1. Declare a [`codequality` report artifact](../yaml/artifacts_reports.md#artifactsreportscodequality) that points to the location of the report file.

You can also use or adapt the [Flake8 CI/CD component](https://gitlab.com/explore/catalog/eakca1/codequality-os-scanners-integration) to run the scan and integrate its output with Code Quality.

#### Pylint

If you already have a [Pylint](https://pypi.org/project/pylint/) job in your CI/CD pipelines, you should add a report to send its output to Code Quality.
To integrate its output:

1. Install [`pylint-gitlab`](https://pypi.org/project/pylint-gitlab/) as a dependency in your project.
1. Add the argument `--output-format=pylint_gitlab.GitlabCodeClimateReporter` to the command you use to run Pylint.
1. Change your `pylint` command to send its output to a file.
1. Declare a [`codequality` report artifact](../yaml/artifacts_reports.md#artifactsreportscodequality) that points to the location of the report file.

You can also use or adapt the [Pylint CI/CD component](https://gitlab.com/explore/catalog/eakca1/codequality-os-scanners-integration) to run the scan and integrate its output with Code Quality.

#### Ruff

If you already have a [Ruff](https://docs.astral.sh/ruff/) job in your CI/CD pipelines, you should add a report to send its output to Code Quality.
To integrate its output:

1. Add the argument `--output-format=gitlab` to the command you use to run Ruff.
1. Change your `ruff check` command to send its output to a file.
1. Declare a [`codequality` report artifact](../yaml/artifacts_reports.md#artifactsreportscodequality) that points to the location of the report file.

You can also use or adapt the [documented Ruff GitLab CI/CD integration](https://docs.astral.sh/ruff/integrations/#gitlab-cicd) to run the scan and integrate its output with Code Quality.

#### golangci-lint

If you already have a [`golangci-lint`](https://golangci-lint.run/) job in your CI/CD pipelines, you should add a report to send its output to Code Quality.
To integrate its output:

1. Add the arguments `--out-format code-climate:gl-code-quality-report.json,line-number` to the command you use to run golangci-lint.
1. Declare a [`codequality` report artifact](../yaml/artifacts_reports.md#artifactsreportscodequality) that points to the location of the report file.

You can also use or adapt the [golangci-lint CI/CD component](https://gitlab.com/explore/catalog/eakca1/codequality-os-scanners-integration) to run the scan and integrate its output with Code Quality.

#### PMD Copy/Paste Detector

The [PMD Copy/Paste Detector (CPD)](https://pmd.github.io/pmd/pmd_userdocs_cpd.html) requires additional configuration because its default output doesn't conform to the required format.

You can use or adapt the [PMD CI/CD component](https://gitlab.com/explore/catalog/eakca1/codequality-os-scanners-integration) to run the scan and integrate its output with Code Quality.

#### SwiftLint

Using [SwiftLint](https://realm.github.io/SwiftLint/) requires additional configuration because its default output doesn't conform to the required format.

You can use or adapt the [Swiftlint CI/CD component](https://gitlab.com/explore/catalog/eakca1/codequality-os-scanners-integration) to run the scan and integrate its output with Code Quality.

#### RuboCop

Using [RuboCop](https://rubocop.org/) requires additional configuration because its default output doesn't conform to the required format.

You can use or adapt the [RuboCop CI/CD component](https://gitlab.com/explore/catalog/eakca1/codequality-os-scanners-integration) to run the scan and integrate its output with Code Quality.

#### Roslynator

Using [Roslynator](https://josefpihrt.github.io/docs/roslynator/) requires additional configuration because its default output doesn't conform to the required format.

You can use or adapt the [Roslynator CI/CD component](https://gitlab.com/explore/catalog/eakca1/codequality-os-scanners-integration) to run the scan and integrate its output with Code Quality.

### Documentation scanning tools

You can use Code Quality to scan any file stored in a repository, even if it isn't code.

#### Vale

If you already have a [Vale](https://vale.sh/) job in your CI/CD pipelines, you should add a report to send its output to Code Quality.
To integrate its output:

1. Create a Vale template file in your repository that defines the required format.
   - You can copy the open source [template used to check GitLab documentation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/vale-json.tmpl).
   - You can also use another open source variant like the one used in the community [`gitlab-ci-utils` Vale project](https://gitlab.com/gitlab-ci-utils/container-images/vale/-/blob/main/vale/vale-glcq.tmpl). This community project also provides [a pre-made container image](https://gitlab.com/gitlab-ci-utils/container-images/vale) that includes the same template so you can use it directly in your pipelines.
1. Add the arguments `--output="$VALE_TEMPLATE_PATH" --no-exit` to the command you use to run Vale.
1. Change your `vale` command to send its output to a file.
1. Declare a [`codequality` report artifact](../yaml/artifacts_reports.md#artifactsreportscodequality) that points to the location of the report file.

You can also use or adapt an open source job definition to run the scan and integrate its output with Code Quality, for example:

- The [Vale linting step](https://gitlab.com/gitlab-org/gitlab/-/blob/94f870b8e4b965a41dd2ad576d50f7eeb271f117/.gitlab/ci/docs.gitlab-ci.yml#L71-87) used to check GitLab documentation.
- The community [`gitlab-ci-utils` Vale project](https://gitlab.com/gitlab-ci-utils/container-images/vale#usage).

#### markdownlint-cli2

If you already have a [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) job in your CI/CD pipelines, you should add a report to send its output to Code Quality.
To integrate its output:

1. Add [`markdownlint-cli2-formatter-codequality`](https://www.npmjs.com/package/markdownlint-cli2-formatter-codequality) as a development dependency in your project.
1. If you don't already have one, create a `.markdownlint-cli2.jsonc` file at the top level of your repository.
1. Add an `outputFormatters` directive to `.markdownlint-cli2.jsonc`:

   ```json
   {
     "outputFormatters": [
       [ "markdownlint-cli2-formatter-codequality" ]
     ]
   }
   ```

1. Declare a [`codequality` report artifact](../yaml/artifacts_reports.md#artifactsreportscodequality) that points to the location of the report file.
   By default, the report file is named `markdownlint-cli2-codequality.json`.
   1. Recommended. Add the report's filename to the repository's `.gitignore` file.

For more details and an example CI/CD job definition, see the [documentation for `markdownlint-cli2-formatter-codequality`](https://www.npmjs.com/package/markdownlint-cli2-formatter-codequality).
