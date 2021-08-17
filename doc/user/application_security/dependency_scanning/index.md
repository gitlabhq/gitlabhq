---
type: reference, howto
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Dependency Scanning **(ULTIMATE)**

The Dependency Scanning feature can automatically find security vulnerabilities in your
dependencies while you're developing and testing your applications. For example, dependency scanning
lets you know if your application uses an external (open source) library that is known to be
vulnerable. You can then take action to protect your application.

## Overview

If you're using [GitLab CI/CD](../../../ci/index.md), you can use dependency scanning to analyze
your dependencies for known vulnerabilities. GitLab scans all dependencies, including transitive
dependencies (also known as nested dependencies). You can take advantage of dependency scanning by
either:

- [Including the dependency scanning template](#configuration)
  in your existing `.gitlab-ci.yml` file.
- Implicitly using
  the [auto dependency scanning](../../../topics/autodevops/stages.md#auto-dependency-scanning)
  provided by [Auto DevOps](../../../topics/autodevops/index.md).

GitLab checks the dependency scanning report, compares the found vulnerabilities
between the source and target branches, and shows the information on the
merge request. The results are sorted by the [severity](../vulnerabilities/severities.md) of the
vulnerability.

![Dependency scanning Widget](img/dependency_scanning_v13_2.png)

## Requirements

To run dependency scanning jobs, by default, you need GitLab Runner with the
[`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
If you're using the shared runners on GitLab.com, this is enabled by default.

WARNING:
If you use your own runners, make sure your installed version of Docker
is **not** `19.03.0`. See [troubleshooting information](#error-response-from-daemon-error-processing-tar-file-docker-tar-relocation-error) for details.

WARNING:
Dependency Scanning does not support run-time installation of compilers and interpreters.
If you have need of this, please explain why by filling out the survey [here](https://docs.google.com/forms/d/e/1FAIpQLScKo7xEYA65rOjPTGIufAyfjPGnCALSJZoTxBlvskfFMEOZMw/viewform).

## Supported languages and package managers

Dependency Scanning automatically detects the languages used in the repository. All analyzers
matching the detected languages are run. There is usually no need to customize the selection of
analyzers. We recommend not specifying the analyzers so you automatically use the full selection
for best coverage, avoiding the need to make adjustments when there are deprecations or removals.
However, you can override the selection using the variable `DS_EXCLUDED_ANALYZERS`.

The language detection relies on CI job [`rules`](../../../ci/yaml/index.md#rules) and searches a
maximum of two directory levels from the repository's root. For example, the
`gemnasium-dependency_scanning` job is enabled if a repository contains either a `Gemfile` or
`api/Gemfile` file, but not if the only supported dependency file is `api/client/Gemfile`.

The following languages and dependency managers are supported:

<style>
table.supported-languages tr:nth-child(even) {
    background-color: transparent;
}

table.supported-languages td {
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}

table.supported-languages tr td:first-child {
    border-left: 0;
}

table.supported-languages tr td:last-child {
    border-right: 0;
}

table.supported-languages ul {
    list-style-type: none;
    padding-left: 0px;
    margin-bottom: 0px;
}
</style>

<table class="supported-languages">
  <thead>
    <tr>
      <th>Language</th>
      <th>Package Manager</th>
      <th>Package Manager Versions</th>
      <th>Supported files</th>
      <th>Analyzer</th>
      <th><a href="#how-multiple-files-are-processed">Processes multiple files?</a></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="2">Ruby</td>
      <td rowspan="2"><a href="https://bundler.io/">Bundler</a></td>
      <td rowspan="2">Any</td>
      <td>
        <ul>
            <li><code>Gemfile.lock</code></li>
            <li><code>gems.locked</code></li>
        </ul>
      </td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>Y</td>
    </tr>
    <tr>
      <td><code>Gemfile.lock</code></td>
      <td><a href="https://github.com/rubysec/bundler-audit">bundler-audit</a></td>
      <td>N</td>
    </tr>
    <tr>
      <td>PHP</td>
      <td><a href="https://getcomposer.org/">Composer</a></td>
      <td>Any</td>
      <td><code>composer.lock</code></td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>Y</td>
    </tr>
    <tr>
      <td>C</td>
      <td rowspan="2"><a href="https://conan.io/">Conan</a></td>
      <td rowspan="2">Any</td>
      <td rowspan="2"><a href="https://docs.conan.io/en/latest/versioning/lockfiles.html"><code>conan.lock</code></a></td>
      <td rowspan="2"><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td rowspan="2">Y</td>
    </tr>
    <tr>
      <td>C++</td>
    </tr>
    <tr>
      <td>Go</td>
      <td><a href="https://golang.org/">Golang</a></td>
      <td>Any</td>
      <td><code>go.sum</code></td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>Y</td>
    </tr>
    <tr>
      <td rowspan="2">Java</td>
      <td><a href="https://gradle.org/">Gradle</a></td>
      <td>Any</td>
      <td>
        <ul>
            <li><code>build.gradle</code></li>
            <li><code>build.gradle.kts</code></li>
        </ul>
      </td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://maven.apache.org/">Maven</a></td>
      <td>Any</td>
      <td><code>pom.xml</code></td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>N</td>
    </tr>
    <tr>
      <td rowspan="3">JavaScript</td>
      <td rowspan="2"><a href="https://www.npmjs.com/">npm</a></td>
      <td rowspan="2">Any</td>
      <td>
        <ul>
            <li><code>package-lock.json</code></li>
            <li><code>npm-shrinkwrap.json</code></li>
        </ul>
      </td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>Y</td>
    </tr>
    <tr>
      <td><code>package.json</code></td>
      <td><a href="https://retirejs.github.io/retire.js/">Retire.js</a></td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://classic.yarnpkg.com/en/">yarn</a></td>
      <td>1.x</td>
      <td><code>yarn.lock</code></td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>Y</td>
    </tr>
    <tr>
      <td>.NET</td>
      <td rowspan="2"><a href="https://www.nuget.org/">NuGet</a></td>
      <td rowspan="2">&gt;= 4.9</td>
      <td rowspan="2"><a href="https://docs.microsoft.com/en-us/nuget/consume-packages/package-references-in-project-files#enabling-lock-file"><code>packages.lock.json</code></a></td>
      <td rowspan="2"><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td rowspan="2">Y</td>
    </tr>
    <tr>
      <td>C#</td>
    </tr>
    <tr>
      <td rowspan="3">Python</td>
      <td><a href="https://setuptools.readthedocs.io/en/latest/">setuptools</a></td>
      <td>Any</td>
      <td><code>setup.py</code></td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://pip.pypa.io/en/stable/">pip</a></td>
      <td>Any</td>
      <td>
        <ul>
            <li><code>requirements.txt</code></li>
            <li><code>requirements.pip</code></li>
            <li><code>requires.txt</code></li>
        </ul>
      </td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://pipenv.pypa.io/en/latest/">Pipenv</a></td>
      <td>Any</td>
      <td>
        <ul>
            <li><a href="https://pipenv.pypa.io/en/latest/basics/#example-pipfile-pipfile-lock"><code>Pipfile</code></a></li>
            <li><a href="https://pipenv.pypa.io/en/latest/basics/#example-pipfile-pipfile-lock"><code>Pipfile.lock</code></a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers">1</a></b></sup></li>
        </ul>
      </td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>N</td>
    </tr>
    <tr>
      <td>Scala</td>
      <td><a href="https://www.scala-sbt.org/">sbt</a><sup><b><a href="#notes-regarding-supported-languages-and-package-managers">2</a></b></sup></td>
      <td>Any</td>
      <td><code>build.sbt</code></td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium">Gemnasium</a></td>
      <td>N</td>
    </tr>
  </tbody>
</table>

### Notes regarding supported languages and package managers

1. The presence of a `Pipfile.lock` file alone will _not_ trigger the analyzer; the presence of a `Pipfile` is still required in order
for the analyzer to be executed. However, if a `Pipfile.lock` file is found, it will be used by `Gemnasium` to scan the exact package
versions listed in this file.

   Support for `Pipfile.lock` files without requiring the presence of a `Pipfile` will be implemented in the following upcoming issue:
   [Dependency Scanning of Pipfile.lock without installing project dependencies](https://gitlab.com/gitlab-org/gitlab/-/issues/299294).

1. Support for [sbt](https://www.scala-sbt.org/) 1.3 and above was added in GitLab 13.9.

### How analyzers are triggered

GitLab relies on [`rules:exists`](../../../ci/yaml/index.md#rulesexists) to start the relevant analyzers for the languages detected by the presence of the
`Supported files` in the repository as shown in the [table above](#supported-languages-and-package-managers).

The current detection logic limits the maximum search depth to two levels. For example, the `gemnasium-dependency_scanning` job is enabled if
a repository contains either a `Gemfile.lock` or `api/Gemfile.lock` file, but not if the only supported dependency file is `api/client/Gemfile.lock`.

### How multiple files are processed

NOTE:
If you've run into problems while scanning multiple files, please contribute a comment to
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/337056).

#### Ruby

The following analyzers are executed, each of which have different behavior when processing multiple files:

- [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)

   Supports multiple lockfiles.

- [bundler-audit](https://github.com/rubysec/bundler-audit)

   Does not support multiple lockfiles. When multiple lockfiles exist, `bundler-audit`
   analyzes the first lockfile discovered while traversing the directory tree in alphabetical order.

We execute both analyzers because they use different sources of vulnerability data. The result is more comprehensive analysis than if only one was executed.

#### Python

We only execute one build in the directory where a requirements file has been detected, such as `requirements.txt` or any
variation of this file (for example, `requirements.pip` or `requires.txt`).

#### Java and Scala

We only execute one build in the directory where a build file has been detected, such as `build.sbt` or `build.gradle`.
Please note, we support the following types of Java project stuctures:

- [multi-project sbt builds](https://www.scala-sbt.org/1.x/docs/Multi-Project.html)
- [multi-project gradle builds](https://docs.gradle.org/current/userguide/intro_multi_project_builds.html)
- [multi-module maven projects](https://maven.apache.org/pom.html#Aggregation)

#### JavaScript

The following analyzers are executed, each of which have different behavior when processing multiple files:

- [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)

   Supports multiple lockfiles

- [Retire.js](https://retirejs.github.io/retire.js/)

   Does not support multiple lockfiles. When multiple lockfiles exist, `Retire.js`
   analyzes the first lockfile discovered while traversing the directory tree in alphabetical order.

We execute both analyzers because they use different sources of vulnerability data. The result is more comprehensive analysis than if only one was executed.

#### PHP, Go, C, C++, .NET, C&#35;

The analyzer for these languages supports multiple lockfiles.

### Future support for additional languages

Plans are underway for supporting the following languages, dependency managers, and dependency files. For details, see the issue link for each.
For workarounds, see the [Troubleshooting section](#troubleshooting)

| Package Managers    | Languages | Supported files | Scan tools | Issue |
| ------------------- | --------- | --------------- | ---------- | ----- |
| [Poetry](https://python-poetry.org/) | Python | `poetry.lock` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) | [GitLab#7006](https://gitlab.com/gitlab-org/gitlab/-/issues/7006) |

## Contribute your scanner

The [Security Scanner Integration](../../../development/integrations/secure.md) documentation explains how to integrate other security scanners into GitLab.

## Configuration

To enable dependency scanning for GitLab 11.9 and later, you must
[include](../../../ci/yaml/index.md#includetemplate) the
[`Dependency-Scanning.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml)
that is provided as a part of your GitLab installation.
For GitLab versions earlier than 11.9, you can copy and use the job as defined
that template.

Add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml
```

The included template creates dependency scanning jobs in your CI/CD
pipeline and scans your project's source code for possible vulnerabilities.
The results are saved as a
[dependency scanning report artifact](../../../ci/yaml/index.md#artifactsreportsdependency_scanning)
that you can later download and analyze. Due to implementation limitations, we
always take the latest dependency scanning artifact available.

### Enable Dependency Scanning via an automatic merge request

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4908) in GitLab 14.1.
> - [Enabled with `sec_dependency_scanning_ui_enable` flag](https://gitlab.com/gitlab-org/gitlab/-/issues/282533) for self-managed GitLab in GitLab 14.1 and is ready for production use.
> - [Feature flag sec_dependency_scanning_ui_enable removed](https://gitlab.com/gitlab-org/gitlab/-/issues/326005) in GitLab 14.2.

To enable Dependency Scanning in a project, you can create a merge request
from the Security Configuration page.

1. In the project where you want to enable Dependency Scanning, navigate to
   **Security & Compliance > Configuration**.
1. In the **Dependency Scanning** row, select **Configure via Merge Request**.

This automatically creates a merge request with the changes necessary to enable Dependency Scanning
that you can review and merge to complete the configuration.

### Customizing the dependency scanning settings

The dependency scanning settings can be changed through [CI/CD variables](#available-cicd-variables) by using the
[`variables`](../../../ci/yaml/index.md#variables) parameter in `.gitlab-ci.yml`.
For example:

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

variables:
  SECURE_LOG_LEVEL: error
```

Because template is [evaluated before](../../../ci/yaml/index.md#include) the pipeline
configuration, the last mention of the variable takes precedence.

### Overriding dependency scanning jobs

WARNING:
Beginning in GitLab 13.0, the use of [`only` and `except`](../../../ci/yaml/index.md#only--except)
is no longer supported. When overriding the template, you must use [`rules`](../../../ci/yaml/index.md#rules) instead.

To override a job definition (for example, to change properties like `variables` or `dependencies`),
declare a new job with the same name as the one to override. Place this new job after the template
inclusion and specify any additional keys under it. For example, this disables `DS_REMEDIATE` for
the `gemnasium` analyzer:

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  variables:
    DS_REMEDIATE: "false"
```

To override the `dependencies: []` attribute, add an override job as above, targeting this attribute:

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  dependencies: ["build"]
```

### Available CI/CD variables

Dependency scanning can be [configured](#customizing-the-dependency-scanning-settings)
using environment variables.

#### Configuring dependency scanning

The following variables allow configuration of global dependency scanning settings.

| CI/CD variables             | Description |
| ----------------------------|------------ |
| `ADDITIONAL_CA_CERT_BUNDLE` | Bundle of CA certs to trust. The bundle of certificates provided here is also used by other tools during the scanning process, such as `git`, `yarn`, or `npm`. See [Using a custom SSL CA certificate authority](#using-a-custom-ssl-ca-certificate-authority) for more details. |
| `DS_EXCLUDED_ANALYZERS`      | Specify the analyzers (by name) to exclude from Dependency Scanning. For more information, see [Dependency Scanning Analyzers](analyzers.md). |
| `DS_DEFAULT_ANALYZERS`      | ([**DEPRECATED - use `DS_EXCLUDED_ANALYZERS` instead**](https://gitlab.com/gitlab-org/gitlab/-/issues/287691)) Override the names of the official default images. For more information, see [Dependency Scanning Analyzers](analyzers.md). |
| `DS_EXCLUDED_PATHS`         | Exclude vulnerabilities from output based on the paths. A comma-separated list of patterns. Patterns can be globs, or file or folder paths (for example, `doc,spec`). Parent directories also match patterns. Default: `"spec, test, tests, tmp"`. |
| `SECURE_ANALYZERS_PREFIX`   | Override the name of the Docker registry providing the official default images (proxy). Read more about [customizing analyzers](analyzers.md). |
| `SECURE_LOG_LEVEL`          | Set the minimum logging level. Messages of this logging level or higher are output. From highest to lowest severity, the logging levels are: `fatal`, `error`, `warn`, `info`, `debug`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10880) in GitLab 13.1. Default: `info`. |

#### Configuring specific analyzers used by dependency scanning

The following variables are used for configuring specific analyzers (used for a specific language/framework).

| CI/CD variable                       | Analyzer           | Default                      | Description |
| ------------------------------------ | ------------------ | ---------------------------- |------------ |
| `BUNDLER_AUDIT_UPDATE_DISABLED`      | `bundler-audit`    | `"false"`                    | Disable automatic updates for the `bundler-audit` analyzer. Use if you're running dependency scanning in an offline, air-gapped environment.|
| `BUNDLER_AUDIT_ADVISORY_DB_URL`      | `bundler-audit`    | `https://github.com/rubysec/ruby-advisory-db` | URL of the advisory database used by bundler-audit. |
| `BUNDLER_AUDIT_ADVISORY_DB_REF_NAME` | `bundler-audit`    | `master`                     | Git ref for the advisory database specified by `BUNDLER_AUDIT_ADVISORY_DB_URL`. |
| `GEMNASIUM_DB_LOCAL_PATH`            | `gemnasium`        | `/gemnasium-db`              | Path to local Gemnasium database. |
| `GEMNASIUM_DB_UPDATE_DISABLED`       | `gemnasium`        | `"false"`                    | Disable automatic updates for the `gemnasium-db` advisory database (For usage see: [examples](#hosting-a-copy-of-the-gemnasium_db-advisory-database))|
| `GEMNASIUM_DB_REMOTE_URL`            | `gemnasium`        | `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git` | Repository URL for fetching the Gemnasium database. |
| `GEMNASIUM_DB_REF_NAME`              | `gemnasium`        | `master`                     | Branch name for remote repository database. `GEMNASIUM_DB_REMOTE_URL` is required. |
| `DS_REMEDIATE`                       | `gemnasium`        | `"true"`                     | Enable automatic remediation of vulnerable dependencies. |
| `DS_JAVA_VERSION`                    | `gemnasium-maven`  | `11`                         | Version of Java. Available versions: `8`, `11`, `13`, `14`, `15`, `16`. |
| `MAVEN_CLI_OPTS`                     | `gemnasium-maven`  | `"-DskipTests --batch-mode"` | List of command line arguments that are passed to `maven` by the analyzer. See an example for [using private repositories](../index.md#using-private-maven-repositories). |
| `GRADLE_CLI_OPTS`                    | `gemnasium-maven`  |                              | List of command line arguments that are passed to `gradle` by the analyzer. |
| `SBT_CLI_OPTS`                       | `gemnasium-maven`  |                              | List of command-line arguments that the analyzer passes to `sbt`. |
| `PIP_INDEX_URL`                      | `gemnasium-python` | `https://pypi.org/simple`    | Base URL of Python Package Index. |
| `PIP_EXTRA_INDEX_URL`                | `gemnasium-python` |                              | Array of [extra URLs](https://pip.pypa.io/en/stable/reference/pip_install/#cmdoption-extra-index-url) of package indexes to use in addition to `PIP_INDEX_URL`. Comma-separated. **Warning:** Please read [the following security consideration](#python-projects) when using this environment variable. |
| `PIP_REQUIREMENTS_FILE`              | `gemnasium-python` |                              | Pip requirements file to be scanned. |
| `DS_PIP_VERSION`                     | `gemnasium-python` |                              | Force the install of a specific pip version (example: `"19.3"`), otherwise the pip installed in the Docker image is used. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12811) in GitLab 12.7) |
| `DS_PIP_DEPENDENCY_PATH`             | `gemnasium-python` |                              | Path to load Python pip dependencies from. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12412) in GitLab 12.2) |
| `DS_PYTHON_VERSION`                  | `retire.js`        |                              | Version of Python. If set to 2, dependencies are installed using Python 2.7 instead of Python 3.6. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12296) in GitLab 12.1, [removed](https://www.python.org/doc/sunset-python-2/) in GitLab 13.7). |
| `RETIREJS_JS_ADVISORY_DB`            | `retire.js`        | `https://raw.githubusercontent.com/RetireJS/retire.js/master/repository/jsrepository.json` | Path or URL to `retire.js` JS vulnerability data file. Note that if the URL hosting the data file uses a custom SSL certificate, for example in an offline installation, you can pass the certificate in the `ADDITIONAL_CA_CERT_BUNDLE` variable. |
| `RETIREJS_NODE_ADVISORY_DB`          | `retire.js`        | `https://raw.githubusercontent.com/RetireJS/retire.js/master/repository/npmrepository.json` | Path or URL to `retire.js` node vulnerability data file. Note that if the URL hosting the data file uses a custom SSL certificate, for example in an offline installation, you can pass the certificate in the `ADDITIONAL_CA_CERT_BUNDLE` variable. |
| `RETIREJS_ADVISORY_DB_INSECURE`      | `retire.js`        | `false`                      | Enable fetching remote JS and Node vulnerability data files (defined by the `RETIREJS_JS_ADVISORY_DB` and `RETIREJS_NODE_ADVISORY_DB` variables) from hosts using an insecure or self-signed SSL (TLS) certificate. |

### Using a custom SSL CA certificate authority

You can use the `ADDITIONAL_CA_CERT_BUNDLE` CI/CD variable to configure a custom SSL CA certificate authority. The `ADDITIONAL_CA_CERT_BUNDLE` value should contain the [text representation of the X.509 PEM public-key certificate](https://tools.ietf.org/html/rfc7468#section-5.1). For example, to configure this value in the `.gitlab-ci.yml` file, use the following:

```yaml
variables:
  ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
      ...
      jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
      -----END CERTIFICATE-----
```

The `ADDITIONAL_CA_CERT_BUNDLE` value can also be configured as a [custom variable in the UI](../../../ci/variables/index.md#custom-cicd-variables), either as a `file`, which requires the path to the certificate, or as a variable, which requires the text representation of the certificate.

### Using private Maven repositories

If your private Maven repository requires login credentials,
you can use the `MAVEN_CLI_OPTS` CI/CD variable.

Read more on [how to use private Maven repositories](../index.md#using-private-maven-repositories).

## Interacting with the vulnerabilities

Once a vulnerability is found, you can interact with it. Read more on how to
[address the vulnerabilities](../vulnerabilities/index.md).

## Solutions for vulnerabilities

Some vulnerabilities can be fixed by applying the solution that GitLab
automatically generates. Read more about the
[solutions for vulnerabilities](../vulnerabilities/index.md#resolve-a-vulnerability).

## Security Dashboard

The Security Dashboard is a good place to get an overview of all the security
vulnerabilities in your groups, projects and pipelines. Read more about the
[Security Dashboard](../security_dashboard/index.md).

## Vulnerabilities database update

For more information about the vulnerabilities database update, see the
[maintenance table](../vulnerabilities/index.md#vulnerability-scanner-maintenance).

## Dependency List

An additional benefit of dependency scanning is the ability to view your
project's dependencies and their known vulnerabilities. Read more about
the [Dependency List](../dependency_list/index.md).

## Reports JSON format

The dependency scanning tool emits a JSON report file. For more information, see the
[schema for this report](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/dependency-scanning-report-format.json).

Here's an example dependency scanning report:

```json-doc
{
  "version": "2.0",
  "vulnerabilities": [
    {
      "id": "51e83874-0ff6-4677-a4c5-249060554eae",
      "category": "dependency_scanning",
      "name": "Regular Expression Denial of Service",
      "message": "Regular Expression Denial of Service in debug",
      "description": "The debug module is vulnerable to regular expression denial of service when untrusted user input is passed into the `o` formatter. It takes around 50k characters to block for 2 seconds making this a low severity issue.",
      "severity": "Unknown",
      "solution": "Upgrade to latest versions.",
      "scanner": {
        "id": "gemnasium",
        "name": "Gemnasium"
      },
      "location": {
        "file": "yarn.lock",
        "dependency": {
          "package": {
            "name": "debug"
          },
          "version": "1.0.5"
        }
      },
      "identifiers": [
        {
          "type": "gemnasium",
          "name": "Gemnasium-37283ed4-0380-40d7-ada7-2d994afcc62a",
          "value": "37283ed4-0380-40d7-ada7-2d994afcc62a",
          "url": "https://deps.sec.gitlab.com/packages/npm/debug/versions/1.0.5/advisories"
        }
      ],
      "links": [
        {
          "url": "https://nodesecurity.io/advisories/534"
        },
        {
          "url": "https://github.com/visionmedia/debug/issues/501"
        },
        {
          "url": "https://github.com/visionmedia/debug/pull/504"
        }
      ]
    },
    {
      "id": "5d681b13-e8fa-4668-957e-8d88f932ddc7",
      "category": "dependency_scanning",
      "name": "Authentication bypass via incorrect DOM traversal and canonicalization",
      "message": "Authentication bypass via incorrect DOM traversal and canonicalization in saml2-js",
      "description": "Some XML DOM traversal and canonicalization APIs may be inconsistent in handling of comments within XML nodes. Incorrect use of these APIs by some SAML libraries results in incorrect parsing of the inner text of XML nodes such that any inner text after the comment is lost prior to cryptographically signing the SAML message. Text after the comment, therefore, has no impact on the signature on the SAML message.\r\n\r\nA remote attacker can modify SAML content for a SAML service provider without invalidating the cryptographic signature, which may allow attackers to bypass primary authentication for the affected SAML service provider.",
      "severity": "Unknown",
      "solution": "Upgrade to fixed version.\r\n",
      "scanner": {
        "id": "gemnasium",
        "name": "Gemnasium"
      },
      "location": {
        "file": "yarn.lock",
        "dependency": {
          "package": {
            "name": "saml2-js"
          },
          "version": "1.5.0"
        }
      },
      "identifiers": [
        {
          "type": "gemnasium",
          "name": "Gemnasium-9952e574-7b5b-46fa-a270-aeb694198a98",
          "value": "9952e574-7b5b-46fa-a270-aeb694198a98",
          "url": "https://deps.sec.gitlab.com/packages/npm/saml2-js/versions/1.5.0/advisories"
        },
        {
          "type": "cve",
          "name": "CVE-2017-11429",
          "value": "CVE-2017-11429",
          "url": "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-11429"
        }
      ],
      "links": [
        {
          "url": "https://github.com/Clever/saml2/commit/3546cb61fd541f219abda364c5b919633609ef3d#diff-af730f9f738de1c9ad87596df3f6de84R279"
        },
        {
          "url": "https://github.com/Clever/saml2/issues/127"
        },
        {
          "url": "https://www.kb.cert.org/vuls/id/475445"
        }
      ]
    }
  ],
  "remediations": [
    {
      "fixes": [
        {
          "id": "5d681b13-e8fa-4668-957e-8d88f932ddc7",
        }
      ],
      "summary": "Upgrade saml2-js",
      "diff": "ZGlmZiAtLWdpdCBhL...OR0d1ZUc2THh3UT09Cg==" // some content is omitted for brevity
    }
  ]
}
```

## Versioning and release process

Please check the [Release Process documentation](https://gitlab.com/gitlab-org/security-products/release/blob/master/docs/release_process.md).

## Contributing to the vulnerability database

You can search the [gemnasium-db](https://gitlab.com/gitlab-org/security-products/gemnasium-db) project
to find a vulnerability in the Gemnasium database.
You can also [submit new vulnerabilities](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md).

## Running dependency scanning in an offline environment

For self-managed GitLab instances in an environment with limited, restricted, or intermittent access
to external resources through the internet, some adjustments are required for dependency scanning
jobs to run successfully. For more information, see [Offline environments](../offline_deployments/index.md).

### Requirements for offline dependency scanning

Here are the requirements for using dependency scanning in an offline environment:

- GitLab Runner with the [`docker` or `kubernetes` executor](#requirements).
- Docker Container Registry with locally available copies of dependency scanning [analyzer](https://gitlab.com/gitlab-org/security-products/analyzers) images.
- If you have a limited access environment you need to allow access, such as using a proxy, to the advisory database: `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git`.
  If you are unable to permit access to `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git` you must host an offline copy of this `git` repository and set the `GEMNASIUM_DB_REMOTE_URL` CI/CD variable to the URL of this repository. For more information on configuration variables, see [Dependency Scanning](#configuring-dependency-scanning).

  This advisory database is constantly being updated, so you must periodically sync your local copy with GitLab.

- _Only if scanning Ruby projects_: Host an offline Git copy of the [advisory database](https://github.com/rubysec/ruby-advisory-db).
- _Only if scanning npm/yarn projects_: Host an offline copy of the [`retire.js`](https://github.com/RetireJS/retire.js/) [node](https://github.com/RetireJS/retire.js/blob/master/repository/npmrepository.json) and [`js`](https://github.com/RetireJS/retire.js/blob/master/repository/jsrepository.json) advisory databases.

Note that GitLab Runner has a [default `pull policy` of `always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy),
meaning the runner tries to pull Docker images from the GitLab container registry even if a local
copy is available. The GitLab Runner [`pull_policy` can be set to `if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)
in an offline environment if you prefer using only locally available Docker images. However, we
recommend keeping the pull policy setting to `always` if not in an offline environment, as this
enables the use of updated scanners in your CI/CD pipelines.

### Make GitLab dependency scanning analyzer images available inside your Docker registry

For dependency scanning with all [supported languages and frameworks](#supported-languages-and-package-managers),
import the following default dependency scanning analyzer images from `registry.gitlab.com` into
your [local Docker container registry](../../packages/container_registry/index.md):

```plaintext
registry.gitlab.com/gitlab-org/security-products/analyzers/gemnasium:2
registry.gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven:2
registry.gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python:2
registry.gitlab.com/gitlab-org/security-products/analyzers/retire.js:2
registry.gitlab.com/gitlab-org/security-products/analyzers/bundler-audit:2
```

The process for importing Docker images into a local offline Docker registry depends on
**your network security policy**. Please consult your IT staff to find an accepted and approved
process by which external resources can be imported or temporarily accessed.
These scanners are [periodically updated](../vulnerabilities/index.md#vulnerability-scanner-maintenance)
with new definitions, and you may be able to make occasional updates on your own.

For details on saving and transporting Docker images as a file, see Docker's documentation on
[`docker save`](https://docs.docker.com/engine/reference/commandline/save/), [`docker load`](https://docs.docker.com/engine/reference/commandline/load/),
[`docker export`](https://docs.docker.com/engine/reference/commandline/export/), and [`docker import`](https://docs.docker.com/engine/reference/commandline/import/).

#### Support for Custom Certificate Authorities

Support for custom certificate authorities was introduced in the following versions.

| Analyzer | Version |
| -------- | ------- |
| `gemnasium` | [v2.8.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/releases/v2.8.0) |
| `gemnasium-maven` | [v2.9.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/releases/v2.9.0) |
| `gemnasium-python` | [v2.7.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python/-/releases/v2.7.0) |
| `retire.js` | [v2.4.0](https://gitlab.com/gitlab-org/security-products/analyzers/retire.js/-/releases/v2.4.0) |
| `bundler-audit` | [v2.4.0](https://gitlab.com/gitlab-org/security-products/analyzers/bundler-audit/-/releases/v2.4.0) |

### Set dependency scanning CI/CD job variables to use local dependency scanning analyzers

Add the following configuration to your `.gitlab-ci.yml` file. You must change the value of
`SECURE_ANALYZERS_PREFIX` to refer to your local Docker container registry. You must also change the
value of `GEMNASIUM_DB_REMOTE_URL` to the location of your offline Git copy of the
[gemnasium-db advisory database](https://gitlab.com/gitlab-org/security-products/gemnasium-db/):

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

variables:
  SECURE_ANALYZERS_PREFIX: "docker-registry.example.com/analyzers"
  GEMNASIUM_DB_REMOTE_URL: "gitlab.example.com/gemnasium-db.git"
```

See explanations of the variables above in the [configuration section](#configuration).

### Specific settings for languages and package managers

See the following sections for configuring specific languages and package managers.

#### JavaScript (npm and yarn) projects

Add the following to the variables section of `.gitlab-ci.yml`:

```yaml
RETIREJS_JS_ADVISORY_DB: "example.com/jsrepository.json"
RETIREJS_NODE_ADVISORY_DB: "example.com/npmrepository.json"
```

#### Ruby (gem) projects

Add the following to the variables section of `.gitlab-ci.yml`:

```yaml
BUNDLER_AUDIT_ADVISORY_DB_REF_NAME: "master"
BUNDLER_AUDIT_ADVISORY_DB_URL: "gitlab.example.com/ruby-advisory-db.git"
```

#### Python (setup tools)

When using self-signed certificates for your private PyPi repository, no extra job configuration (aside
from the template `.gitlab-ci.yml` above) is needed. However, you must update your `setup.py` to
ensure that it can reach your private repository. Here is an example configuration:

1. Update `setup.py` to create a `dependency_links` attribute pointing at your private repository for each
   dependency in the `install_requires` list:

   ```python
   install_requires=['pyparsing>=2.0.3'],
   dependency_links=['https://pypi.example.com/simple/pyparsing'],
   ```

1. Fetch the certificate from your repository URL and add it to the project:

   ```shell
   echo -n | openssl s_client -connect pypi.example.com:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > internal.crt
   ```

1. Point `setup.py` at the newly downloaded certificate:

   ```python
   import setuptools.ssl_support
   setuptools.ssl_support.cert_paths = ['internal.crt']
   ```

## Hosting a copy of the gemnasium_db advisory database

The [`gemnasium_db`](https://gitlab.com/gitlab-org/security-products/gemnasium-db) Git repository is
used by `gemnasium`, `gemnasium-maven`, and `gemnasium-python` as the source of vulnerability data.
This repository updates at scan time to fetch the latest advisories. However, due to a restricted
networking environment, running this update is sometimes not possible. In this case, a user can do
one of the following:

- [Host a copy of the advisory database](#host-a-copy-of-the-advisory-database)
- [Use a local clone](#use-a-local-clone)

### Host a copy of the advisory database

If [gemnasium-db](https://gitlab.com/gitlab-org/security-products/gemnasium-db) is not reachable
from within the environment, the user can host their own Git copy. Then the analyzer can be
instructed to update the database from the user's copy by using `GEMNASIUM_DB_REMOTE_URL`:

```yaml
variables:
  GEMNASIUM_DB_REMOTE_URL: https://users-own-copy.example.com/gemnasium-db/.git

...
```

### Use a local clone

If a hosted copy is not possible, then the user can clone [gemnasium-db](https://gitlab.com/gitlab-org/security-products/gemnasium-db)
or create an archive before the scan and point the analyzer to the directory (using:
`GEMNASIUM_DB_LOCAL_PATH`). Turn off the analyzer's self-update mechanism (using:
`GEMNASIUM_DB_UPDATE_DISABLED`). In this example, the database directory is created in the
`before_script`, before the `gemnasium` analyzer's scan job:

```yaml
...

gemnasium-dependency_scanning:
  variables:
    GEMNASIUM_DB_LOCAL_PATH: ./gemnasium-db-local
    GEMNASIUM_DB_UPDATE_DISABLED: "true"
  before_script:
    - mkdir $GEMNASIUM_DB_LOCAL_PATH
    - tar -xzf gemnasium_db.tar.gz -C $GEMNASIUM_DB_LOCAL_PATH
```

## Warnings

### Python projects

Extra care needs to be taken when using the [`PIP_EXTRA_INDEX_URL`](https://pipenv.pypa.io/en/latest/cli/#envvar-PIP_EXTRA_INDEX_URL)
environment variable due to a possible exploit documented by [CVE-2018-20225](https://nvd.nist.gov/vuln/detail/CVE-2018-20225):

> An issue was discovered in pip (all versions) because it installs the version with the highest version number, even if the user had
intended to obtain a private package from a private index. This only affects use of the `PIP_EXTRA_INDEX_URL` option, and exploitation
requires that the package does not already exist in the public index (and thus the attacker can put the package there with an arbitrary
version number).

## Limitations

### Referencing local dependencies using a path in JavaScript projects

The [Retire.js](https://gitlab.com/gitlab-org/security-products/analyzers/retire.js) analyzer
doesn't support dependency references made with [local paths](https://docs.npmjs.com/cli/v6/configuring-npm/package-json/#local-paths)
in the `package.json` of JavaScript projects. The dependency scan outputs the following error for
such references:

```plaintext
ERROR: Could not find dependencies: <dependency-name>. You may need to run npm install
```

As a workaround, add the [`retire.js`](analyzers.md) analyzer to
[`DS_EXCLUDED_ANALYZERS`](#configuring-dependency-scanning).

## Troubleshooting

### Working around missing support for certain languages or package managers

As noted in the ["Supported languages" section](#supported-languages-and-package-managers)
some dependency definition files are not yet supported.
However, Dependency Scanning can be achieved if
the language, a package manager, or a third-party tool
can convert the definition file
into a supported format.

Generally, the approach is the following:

1. Define a dedicated converter job in your `.gitlab-ci.yml` file.
   Use a suitable Docker image, script, or both to facilitate the conversion.
1. Let that job upload the converted, supported file as an artifact.
1. Add [`dependencies: [<your-converter-job>]`](../../../ci/yaml/index.md#dependencies)
   to your `dependency_scanning` job to make use of the converted definitions files.

For example, the unsupported `poetry.lock` file can be
[converted](https://python-poetry.org/docs/cli/#export)
to the supported `requirements.txt` as follows.

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

stages:
  - test

variables:
  PIP_REQUIREMENTS_FILE: "requirements-converted.txt"

gemnasium-python-dependency_scanning:
  # Work around https://gitlab.com/gitlab-org/gitlab/-/issues/7006
  before_script:
    - pip install poetry  # Or via another method: https://python-poetry.org/docs/#installation
    - poetry export --output="$PIP_REQUIREMENTS_FILE"
    - rm poetry.lock pyproject.toml
```

### `Error response from daemon: error processing tar file: docker-tar: relocation error`

This error occurs when the Docker version that runs the dependency scanning job is `19.03.0`.
Consider updating to Docker `19.03.1` or greater. Older versions are not
affected. Read more in
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/13830#note_211354992 "Current SAST container fails").

### Getting warning message `gl-dependency-scanning-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../ci/pipelines/job_artifacts.md#error-message-no-files-to-upload).

### Limitation when using rules:exists

The [dependency scanning CI template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml)
uses the [`rules:exists`](../../../ci/yaml/index.md#rulesexists)
syntax. This directive is limited to 10000 checks and always returns `true` after reaching this
number. Because of this, and depending on the number of files in your repository, a dependency
scanning job might be triggered even if the scanner doesn't support your project.

### Issues building projects with npm or yarn packages relying on Python 2

[Python 2 was removed](https://www.python.org/doc/sunset-python-2/) from the `retire.js` analyzer in GitLab 13.7 (analyzer version 2.10.1). Projects using packages
with a dependency on this version of Python should use `retire.js` version 2.10.0 or lower (for example, `registry.gitlab.com/gitlab-org/security-products/analyzers/retire.js:2.10.0`).

### Error: `dependency_scanning is used for configuration only, and its script should not be executed`

For information on this, see the [GitLab Secure troubleshooting section](../index.md#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed).
