---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Repository X-Ray gives Code Suggestions more insight into your project's codebase and dependencies."
---

# Repository X-Ray

DETAILS:
**Tier:** Premium with GitLab Duo Pro or Ultimate with [GitLab Duo Pro or Enterprise](../../../../subscriptions/subscription-add-ons.md)
**Offering:** GitLab.com, Self-managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12060) in GitLab 16.7.

Repository X-Ray enhances [GitLab Duo Code Suggestions](index.md) by providing additional context to improve the accuracy and relevance of code recommendations.

Repository X-Ray gives the code assistant more insight into the project's codebase and dependencies to generate better suggestions. It does this by analyzing key project configuration files such as `Gemfile.lock`, `package.json`, and `go.mod` to build additional context.

By understanding the frameworks, libraries and other dependencies in use, Repository X-Ray helps the code assistant tailor suggestions to match the coding patterns, styles and technologies used in the project. This results in code recommendations that integrate more seamlessly and follow best practices for that stack.

## Enable Repository X-Ray

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/476180) in GitLab 17.4 [with a flag](../../../feature_flags.md) named `ai_enable_internal_repository_xray_service`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

The Repository X-Ray service is automatically enabled if:

- You have enabled the `ai_enable_internal_repository_xray_service` feature flag.
- Your project has access to [GitLab Duo Code Suggestions](index.md).

## Supported languages and package managers

The Repository X-Ray searches a maximum of two directory levels from the repository's root. For example, it supports `Gemfile.lock`, `api/Gemfile.lock`, or `api/client/Gemfile.lock`, but not `api/v1/client/Gemfile.lock`. For each language, only the first matching configuration file is processed. Where available, lock files take precedence over their non-lock file counterparts.

| Language   | Package manager | Configuration file   | GitLab version |
| ---------- |-----------------| -------------------- | -------------- |
| C++        | Conan           | `conanfile.txt`      | 17.4 or later  |
| Go         | Go Modules      | `go.mod`             | 17.4 or later  |
| Java       | Gradle          | `build.gradle`       | 17.4 or later  |
| Java       | Maven           | `pom.xml`            | 17.4 or later  |
| Ruby       | RubyGems        | `Gemfile.lock`       | 17.4 or later  |

## Enable Repository X-Ray in your CI pipeline (deprecated)

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/-/epics/14100) in GitLab 17.4.

Prerequisites:

- You must have access to [GitLab Duo Code Suggestions](index.md) in the project.
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
