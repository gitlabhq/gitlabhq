---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Repository X-Ray gives Code Suggestions more insight into your project's codebase and dependencies."
title: Repository X-Ray
---

DETAILS:
**Tier:** Premium with GitLab Duo Pro, Ultimate with GitLab Duo Pro or Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12060) in GitLab 16.7.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.

Repository X-Ray automatically enriches:

- Code generation requests for [GitLab Duo Code Suggestions](_index.md) by providing additional context about a project's dependencies to improve the accuracy and relevance of code recommendations.
- Requests to [refactor code](../../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide), [fix code](../../../gitlab_duo_chat/examples.md#fix-code-in-the-ide), and [write tests](../../../gitlab_duo_chat/examples.md#write-tests-in-the-ide).

To do this, Repository X-Ray gives the code assistant more insight into the project's codebase and dependencies by:

- Searching for dependency manager configuration files (for example, `Gemfile.lock`, `package.json`, `go.mod`).
- Extracting a list of libraries from their content.
- Providing the extracted list as additional context to be used by GitLab Duo Code Suggestions in code generation, refactor code, fix code, and write test requests.

By understanding the libraries and other dependencies in use, Repository X-Ray helps the code assistant
tailor suggestions to match the coding patterns, styles, and technologies used in the project. This results
in code suggestions that integrate more seamlessly and follow best practices for the given stack.

NOTE:
Repository X-Ray only enhances code generation requests and not code completion requests.

## How Repository X-Ray works

> - Maximum number of libraries [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/500365) in GitLab 17.6.

When you push a new commit to your project's default branch, Repository X-Ray triggers a background job.
This job scans and parses the applicable configuration files in your repository.

Typically, only one scanning job runs at a time in each project. If a second scan is triggered while a
scan is already in progress, that second scan waits until the first scan is complete before executing.
This could result in a small delay before the latest configuration file data is parsed and updated in the database.

When a code generation request is made, a maximum of 300 libraries from the parsed data is included in the prompt as additional context.

## Enable Repository X-Ray

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/476180) in GitLab 17.4 [with a flag](../../../feature_flags.md) named `ai_enable_internal_repository_xray_service`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/483928) in GitLab 17.6. Feature flag `ai_enable_internal_repository_xray_service` removed.

The Repository X-Ray service is automatically enabled if your project has access to [GitLab Duo Code Suggestions](_index.md).

## Supported languages and dependency managers

The Repository X-Ray searches a maximum of two directory levels from the repository's root. For example, it supports `Gemfile.lock`, `api/Gemfile.lock`, or `api/client/Gemfile.lock`, but not `api/v1/client/Gemfile.lock`. For each language, only the first matching dependency manager is processed. Where available, lock files take precedence over their non-lock file counterparts.

| Language   | Dependency manager | Configuration file                  | GitLab version |
| ---------- |--------------------| ----------------------------------- | -------------- |
| C/C++      | Conan              | `conanfile.py`                      | 17.5 or later  |
| C/C++      | Conan              | `conanfile.txt`                     | 17.5 or later  |
| C/C++      | vcpkg              | `vcpkg.json`                        | 17.5 or later  |
| C#         | NuGet              | `*.csproj`                          | 17.5 or later  |
| Go         | Go Modules         | `go.mod`                            | 17.4 or later  |
| Java       | Gradle             | `build.gradle`                      | 17.4 or later  |
| Java       | Maven              | `pom.xml`                           | 17.4 or later  |
| JavaScript | NPM                | `package-lock.json`, `package.json` | 17.5 or later  |
| Kotlin     | Gradle             | `build.gradle.kts`                  | 17.5 or later  |
| PHP        | Composer           | `composer.lock`, `composer.json`    | 17.5 or later  |
| Python     | Conda              | `environment.yml`                   | 17.5 or later  |
| Python     | Pip                | `*requirements*.txt` <sup>1</sup>   | 17.5 or later  |
| Python     | Poetry             | `poetry.lock`, `pyproject.toml`     | 17.5 or later  |
| Ruby       | RubyGems           | `Gemfile.lock`                      | 17.4 or later  |

**Footnotes**:

1. For Python Pip, all configuration files matching the `*requirements*.txt` glob pattern are processed.

<!--- start_remove The following content will be removed on remove_date: '2025-08-15' -->

## Enable Repository X-Ray in your CI pipeline (deprecated)

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/500146) in GitLab 17.6
and is planned for removal in 18.0. Use [Enable Repository X-Ray](#enable-repository-x-ray) instead.

Prerequisites:

- You must have access to [GitLab Duo Code Suggestions](_index.md) in the project.
- GitLab Runner must be set up and enabled for the project, because Repository X-Ray runs analysis pipelines using GitLab runners.

To enable Repository X-Ray, add the following definition job to the project's `.gitlab-ci.yml`.

```yaml
xray:
  stage: build
  image: registry.gitlab.com/gitlab-org/code-creation/repository-x-ray:latest
  allow_failure: true
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  variables:
    OUTPUT_DIR: reports
  script:
    - x-ray-scan -p "$CI_PROJECT_DIR" -o "$OUTPUT_DIR"
  artifacts:
    reports:
      repository_xray: "$OUTPUT_DIR/*/*.json"
```

- The `$OUTPUT_DIR` environment variable defines the:
  - Output directory for reports.
  - Path that artifacts are uploaded from.
- The added rules restrict the job to the default branch only. Restricting the job this way ensures development changes do not impact the baseline X-Ray data used for production Code Suggestions.

After the initial x-ray job completes and uploads the repository analysis reports, no further action is required. Repository X-Ray automatically enriches all code generation requests from that point forward.

The X-Ray data for your project updates each time a CI/CD pipeline containing the `xray`
job is run. To learn more about pipeline configuration and triggers, see the
[pipelines documentation](../../../../ci/pipelines/merge_request_pipelines.md).

### Supported languages and package managers

| Language   | Package Manager | Configuration File   |
| ---------- |-----------------| -------------------- |
| Go         | Go Modules      | `go.mod`             |
| JavaScript | NPM, Yarn       | `package.json`       |
| Ruby       | RubyGems        | `Gemfile.lock`       |
| Python     | Poetry          | `pyproject.toml`     |
| Python     | Pip             | `requirements.txt`   |
| Python     | Conda           | `environment.yml`    |
| PHP        | Composer        | `composer.json`      |
| Java       | Maven           | `pom.xml`            |
| Java       | Gradle          | `build.gradle`       |
| Kotlin     | Gradle          | `build.gradle.kts`   |
| C#         | NuGet           | `*.csproj`           |
| C/C++      | Conan           | `conanfile.txt`      |
| C/C++      | Conan           | `conanfile.py`       |
| C/C++      | vcpkg           | `vcpkg.json`         |

### Troubleshooting

#### `401: Unauthorized` when running Repository X-Ray

When running Repository X-Ray, you might get an error that states `401: Unauthorized`.

A Duo Pro add-on is linked to a group when you buy that add-on. To solve the error, ensure
that your current project is part of a group with the Duo Pro add-on.

This link can be either of the following:

- Direct, that is, the project is in a group that has the Duo Pro add-on.
- Indirect, for example, the parent group of the current project's group has the Duo Pro add-on.

<!--- end_remove -->
