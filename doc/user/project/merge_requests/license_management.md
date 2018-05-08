# License Management

> [Introduced][ee-5483] in [GitLab Ultimate][ee] 10.8.

## Overview

If you are using [GitLab CI/CD][ci], you can search your project dependencies for their licenses
using License Management, either by
including the CI job in your [existing `.gitlab-ci.yml` file][cc-docs] or
by implicitly using [Auto License Management](../../../topics/autodevops/index.md#auto-dependency-scanning)
that is provided by [Auto DevOps](../../../topics/autodevops/index.md).

Going a step further, GitLab can show the licenses list right in the merge
request widget area.

## Use cases

It helps you find licenses that you don't want to use in your project and see
which dependencies use them. For example, your application is using an external (open source)
library whose license is incompatible with yours.

## Supported languages and dependency managers

The following languages and dependency managers are supported.

| Language (package managers)                                                 |
|-----------------------------------------------------------------------------|
| Bower ([Bower](https://bower.io/))                                          |
| Go ([Godep](https://github.com/tools/godep), go get)                        |
| Java ([Gradle](https://gradle.org/), [Maven](https://maven.apache.org/))    |
| JavaScript ([npm](https://www.npmjs.com/))                                  |
| .NET ([Nuget](https://www.nuget.org/))                                      |
| Python ([pip](https://pip.pypa.io/en/stable/))                              |
| Ruby ([gem](https://rubygems.org/))                                         |

## How it works

First of all, you need to define a job named `license_management` in your
`.gitlab-ci.yml` file. [Check how the `license_management` job should look like][cc-docs].

In order for the report to show in the merge request, there are two
prerequisites:

- the specified job **must** be named `license_management`
- the resulting report **must** be named `gl-license-report.json`
  and uploaded as an artifact

The `license_management` job will search the application dependencies for licenses,
the resulting JSON file will be uploaded as an artifact, and
GitLab will then check this file and show the information inside the merge
request.

![License Management Widget](img/license_management.jpg)

[ee-5483]: https://gitlab.com/gitlab-org/gitlab-ee/issues/5483
[ee]: https://about.gitlab.com/products/
[ci]: ../../../ci/README.md
[cc-docs]: ../../../ci/examples/license_management.md
