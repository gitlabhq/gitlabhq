---
stage: AI-powered
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Repository X-Ray gives Code Suggestions more insight into your project's codebase and dependencies.
title: Repository X-Ray
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Pro or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12060) in GitLab 16.7.
- Changed to require GitLab Duo add-on in GitLab 17.6 and later.

{{< /history >}}

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

{{< alert type="note" >}}

Repository X-Ray only enhances code generation requests and not code completion requests.

{{< /alert >}}

## How Repository X-Ray works

{{< history >}}

- Maximum number of libraries [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/500365) in GitLab 17.6.

{{< /history >}}

When you push a new commit to your project's default branch, Repository X-Ray triggers a background job.
This job scans and parses the applicable configuration files in your repository.

Typically, only one scanning job runs at a time in each project. If a second scan is triggered while a
scan is already in progress, that second scan waits until the first scan is complete before executing.
This could result in a small delay before the latest configuration file data is parsed and updated in the database.

When a code generation request is made, a maximum of 300 libraries from the parsed data is included in the prompt as additional context.

## Enable Repository X-Ray

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/476180) in GitLab 17.4 [with a flag](../../../../administration/feature_flags/list.md) named `ai_enable_internal_repository_xray_service`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/483928) in GitLab 17.6. Feature flag `ai_enable_internal_repository_xray_service` removed.

{{< /history >}}

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

Footnotes:

1. For Python Pip, all configuration files matching the `*requirements*.txt` glob pattern are processed.
