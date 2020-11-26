---
type: reference, howto
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Dependency Scanning **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5105) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.7.

GitLab's Dependency Scanning feature can automatically find security vulnerabilities in your
dependencies while you're developing and testing your applications. For example, dependency scanning
lets you know if your application uses an external (open source) library that is known to be
vulnerable. You can then take action to protect your application.

## Overview

If you're using [GitLab CI/CD](../../../ci/README.md), you can use dependency scanning to analyze
your dependencies for known vulnerabilities. GitLab scans all dependencies, including transitive
dependencies (also known as nested dependencies). You can take advantage of dependency scanning by
either [including the dependency scanning template](#configuration)
in your existing `.gitlab-ci.yml` file, or by implicitly using
the [auto dependency scanning](../../../topics/autodevops/stages.md#auto-dependency-scanning)
provided by [Auto DevOps](../../../topics/autodevops/index.md).

GitLab checks the dependency scanning report, compares the found vulnerabilities
between the source and target branches, and shows the information on the
merge request.

![Dependency scanning Widget](img/dependency_scanning_v13_2.png)

The results are sorted by the severity of the vulnerability:

1. Critical
1. High
1. Medium
1. Low
1. Unknown
1. Everything else

## Requirements

To run dependency scanning jobs, by default, you need GitLab Runner with the
[`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
If you're using the shared runners on GitLab.com, this is enabled by default.

CAUTION: **Caution:**
If you use your own runners, make sure your installed version of Docker
is **not** `19.03.0`. See [troubleshooting information](#error-response-from-daemon-error-processing-tar-file-docker-tar-relocation-error) for details.

## Supported languages and package managers

GitLab relies on [`rules`](../../../ci/yaml/README.md#rules) to start relevant analyzers depending on the languages detected in the repository.
The current detection logic limits the maximum search depth to two levels. For example, the `gemnasium-dependency_scanning` job is enabled if a repository contains either a `Gemfile` or `api/Gemfile` file, but not if the only supported dependency file is `api/client/Gemfile`.

The following languages and dependency managers are supported:

| Package Managers | Languages  | Supported files | Scan tools |
| ------------------- | --------- | --------------- | ------------ |
| [Bundler](https://bundler.io/) | Ruby | `Gemfile.lock`, `gems.locked` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium), [bundler-audit](https://github.com/rubysec/bundler-audit) |
| [Composer](https://getcomposer.org/) | PHP | `composer.lock` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium) |
| [Conan](https://conan.io/) | C, C++ | [`conan.lock`](https://docs.conan.io/en/latest/versioning/lockfiles.html) | [Gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium) |
| [Golang](https://golang.org/) | Go | `go.sum` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium) |
| [Gradle](https://gradle.org/), [Maven](https://maven.apache.org/) | Java | `build.gradle`, `build.gradle.kts`, `pom.xml` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium) |
| [npm](https://www.npmjs.com/), [yarn](https://classic.yarnpkg.com/en/) | JavaScript | `package-lock.json`, `npm-shrinkwrap.json`, `yarn.lock` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium), [Retire.js](https://retirejs.github.io/retire.js/) |
| [NuGet](https://www.nuget.org/) 4.9+ | .NET, C# | [`packages.lock.json`](https://docs.microsoft.com/en-us/nuget/consume-packages/package-references-in-project-files#enabling-lock-file) | [Gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium) |
| [setuptools](https://setuptools.readthedocs.io/en/latest/), [pip](https://pip.pypa.io/en/stable/), [Pipenv](https://pipenv.pypa.io/en/latest/) | Python | `setup.py`, `requirements.txt`, `requirements.pip`, `requires.txt`, `Pipfile` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium) |
| [sbt](https://www.scala-sbt.org/) 1.2 and below ([Ivy](http://ant.apache.org/ivy/)) | Scala | `build.sbt` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium) |

Plans are underway for supporting the following languages, dependency managers, and dependency files. For details, see the issue link for each.

| Package Managers    | Languages | Supported files | Scan tools | Issue |
| ------------------- | --------- | --------------- | ---------- | ----- |
| [Pipenv](https://pipenv.pypa.io/en/latest/) | Python | `Pipfile.lock` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium) | [GitLab#11756](https://gitlab.com/gitlab-org/gitlab/-/issues/11756) |
| [Poetry](https://python-poetry.org/) | Python | `poetry.lock` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium) | [GitLab#7006](https://gitlab.com/gitlab-org/gitlab/-/issues/7006) |
| [sbt](https://www.scala-sbt.org/) 1.3+ ([Coursier](https://get-coursier.io/))| Scala | `build.sbt` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium) | [GitLab#271345](https://gitlab.com/gitlab-org/gitlab/-/issues/271345) |

## Contribute your scanner

The [Security Scanner Integration](../../../development/integrations/secure.md) documentation explains how to integrate other security scanners into GitLab.

## Configuration

To enable dependency scanning for GitLab 11.9 and later, you must
[include](../../../ci/yaml/README.md#includetemplate) the
[`Dependency-Scanning.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml)
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
[dependency scanning report artifact](../../../ci/pipelines/job_artifacts.md#artifactsreportsdependency_scanning)
that you can later download and analyze. Due to implementation limitations, we
always take the latest dependency scanning artifact available.

### Customizing the dependency scanning settings

The dependency scanning settings can be changed through [environment variables](#available-variables) by using the
[`variables`](../../../ci/yaml/README.md#variables) parameter in `.gitlab-ci.yml`.
For example:

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

variables:
  DS_PYTHON_VERSION: 2
```

Because template is [evaluated before](../../../ci/yaml/README.md#include) the pipeline
configuration, the last mention of the variable takes precedence.

### Overriding dependency scanning jobs

CAUTION: **Deprecation:**
Beginning in GitLab 13.0, the use of [`only` and `except`](../../../ci/yaml/README.md#onlyexcept-basic)
is no longer supported. When overriding the template, you must use [`rules`](../../../ci/yaml/README.md#rules) instead.

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

### Available variables

Dependency scanning can be [configured](#customizing-the-dependency-scanning-settings)
using environment variables.

#### Configuring dependency scanning

The following variables allow configuration of global dependency scanning settings.

| Environment variable                    | Description |
| --------------------------------------- |------------ |
| `SECURE_ANALYZERS_PREFIX`               | Override the name of the Docker registry providing the official default images (proxy). Read more about [customizing analyzers](analyzers.md). |
| `DS_DEFAULT_ANALYZERS`                  | Override the names of the official default images. Read more about [customizing analyzers](analyzers.md). |
| `ADDITIONAL_CA_CERT_BUNDLE`             | Bundle of CA certs to trust. The bundle of certificates provided here is also used by other tools during the scanning process, such as `git`, `yarn`, or `npm`. |
| `DS_EXCLUDED_PATHS`                     | Exclude vulnerabilities from output based on the paths. A comma-separated list of patterns. Patterns can be globs, or file or folder paths (for example, `doc,spec`). Parent directories also match patterns. Default: `"spec, test, tests, tmp"` |
| `SECURE_LOG_LEVEL`                      | Set the minimum logging level. Messages of this logging level or higher are output. From highest to lowest severity, the logging levels are: `fatal`, `error`, `warn`, `info`, `debug`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10880) in GitLab 13.1. Default: `info` |

#### Configuring specific analyzers used by dependency scanning

The following variables are used for configuring specific analyzers (used for a specific language/framework).

| Environment variable                    | Analyzer           | Default                      | Description |
| --------------------------------------- | ------------------ | ---------------------------- |------------ |
| `GEMNASIUM_DB_LOCAL_PATH`               | `gemnasium`        | `/gemnasium-db`              | Path to local Gemnasium database. |
| `GEMNASIUM_DB_REMOTE_URL`               | `gemnasium`        | `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git` | Repository URL for fetching the Gemnasium database. |
| `GEMNASIUM_DB_REF_NAME`                 | `gemnasium`        | `master`                     | Branch name for remote repository database. `GEMNASIUM_DB_REMOTE_URL` is required. |
| `DS_REMEDIATE`                          | `gemnasium`        | `"true"`                     | Enable automatic remediation of vulnerable dependencies.  |
| `PIP_INDEX_URL`                         | `gemnasium-python` | `https://pypi.org/simple`    | Base URL of Python Package Index. |
| `PIP_EXTRA_INDEX_URL`                   | `gemnasium-python` |                              | Array of [extra URLs](https://pip.pypa.io/en/stable/reference/pip_install/#cmdoption-extra-index-url) of package indexes to use in addition to `PIP_INDEX_URL`. Comma-separated. |
| `PIP_REQUIREMENTS_FILE`                 | `gemnasium-python` |                              | Pip requirements file to be scanned. |
| `DS_PIP_VERSION`                        | `gemnasium-python` |                              | Force the install of a specific pip version (example: `"19.3"`), otherwise the pip installed in the Docker image is used. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12811) in GitLab 12.7) |
| `DS_PIP_DEPENDENCY_PATH`                | `gemnasium-python` |                              | Path to load Python pip dependencies from. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12412) in GitLab 12.2) |
| `DS_PYTHON_VERSION`                     | `retire.js`        |                              | Version of Python. If set to 2, dependencies are installed using Python 2.7 instead of Python 3.6. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12296) in GitLab 12.1)|
| `DS_JAVA_VERSION`                       | `gemnasium-maven`  | `11`                         | Version of Java. Available versions: `8`, `11`, `13`, `14`. Maven and Gradle use the Java version specified by this value. |
| `MAVEN_CLI_OPTS`                        | `gemnasium-maven`  | `"-DskipTests --batch-mode"` | List of command line arguments that are passed to `maven` by the analyzer. See an example for [using private repositories](../index.md#using-private-maven-repos). |
| `GRADLE_CLI_OPTS`                       | `gemnasium-maven`  |                              | List of command line arguments that are passed to `gradle` by the analyzer. |
| `SBT_CLI_OPTS`                          | `gemnasium-maven`  |                              | List of command-line arguments that the analyzer passes to `sbt`. |
| `BUNDLER_AUDIT_UPDATE_DISABLED`         | `bundler-audit`    | `"false"`                    | Disable automatic updates for the `bundler-audit` analyzer. Useful if you're running dependency scanning in an offline, air-gapped environment.|
| `BUNDLER_AUDIT_ADVISORY_DB_URL`         | `bundler-audit`    | `https://github.com/rubysec/ruby-advisory-db` | URL of the advisory database used by bundler-audit. |
| `BUNDLER_AUDIT_ADVISORY_DB_REF_NAME`    | `bundler-audit`    | `master`                     | Git ref for the advisory database specified by `BUNDLER_AUDIT_ADVISORY_DB_URL`. |
| `RETIREJS_JS_ADVISORY_DB`               | `retire.js`        | `https://raw.githubusercontent.com/RetireJS/retire.js/master/repository/jsrepository.json` | Path or URL to `retire.js` JS vulnerability data file. Note that if the URL hosting the data file uses a custom SSL certificate, for example in an offline installation, you can pass the certificate in the `ADDITIONAL_CA_CERT_BUNDLE` environment variable. |
| `RETIREJS_NODE_ADVISORY_DB`             | `retire.js`        | `https://raw.githubusercontent.com/RetireJS/retire.js/master/repository/npmrepository.json` | Path or URL to `retire.js` node vulnerability data file. Note that if the URL hosting the data file uses a custom SSL certificate, for example in an offline installation, you can pass the certificate in the `ADDITIONAL_CA_CERT_BUNDLE` environment variable. |
| `RETIREJS_ADVISORY_DB_INSECURE`         | `retire.js`        | `false`                      | Enable fetching remote JS and Node vulnerability data files (defined by the `RETIREJS_JS_ADVISORY_DB` and `RETIREJS_NODE_ADVISORY_DB` variables) from hosts using an insecure or self-signed SSL (TLS) certificate. |

### Using private Maven repos

If your private Maven repository requires login credentials,
you can use the `MAVEN_CLI_OPTS` environment variable.

Read more on [how to use private Maven repositories](../index.md#using-private-maven-repos).

## Interacting with the vulnerabilities

Once a vulnerability is found, you can interact with it. Read more on how to
[interact with the vulnerabilities](../index.md#interacting-with-the-vulnerabilities).

## Solutions for vulnerabilities (auto-remediation)

Some vulnerabilities can be fixed by applying the solution that GitLab
automatically generates. Read more about the
[solutions for vulnerabilities](../index.md#automatic-remediation-for-vulnerabilities).

## Security Dashboard

The Security Dashboard is a good place to get an overview of all the security
vulnerabilities in your groups, projects and pipelines. Read more about the
[Security Dashboard](../security_dashboard/index.md).

## Vulnerabilities database update

For more information about the vulnerabilities database update, check the
[maintenance table](../index.md#maintenance-and-update-of-the-vulnerabilities-database).

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
  If you are unable to permit access to `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git` you must host an offline copy of this `git` repository and set the `GEMNASIUM_DB_REMOTE_URL` variable to the URL of this repository. For more information on configuration variables, see [Dependency Scanning](#configuring-dependency-scanning).

  This advisory database is constantly being updated, so you must periodically sync your local copy with GitLab's.

- _Only if scanning Ruby projects_: Host an offline Git copy of the [advisory database](https://github.com/rubysec/ruby-advisory-db).
- _Only if scanning npm/yarn projects_: Host an offline copy of the [retire.js](https://github.com/RetireJS/retire.js/) [node](https://github.com/RetireJS/retire.js/blob/master/repository/npmrepository.json) and [js](https://github.com/RetireJS/retire.js/blob/master/repository/jsrepository.json) advisory databases.

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
Note that these scanners are [updated periodically](../index.md#maintenance-and-update-of-the-vulnerabilities-database)
with new definitions, so consider if you can make periodic updates yourself.

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

### Set dependency scanning CI job variables to use local dependency scanning analyzers

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

#### Python (setuptools)

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

## Limitations

### Referencing local dependencies using a path in JavaScript projects

The [Retire.js](https://gitlab.com/gitlab-org/security-products/analyzers/retire.js) analyzer
doesn't support dependency references made with [local paths](https://docs.npmjs.com/files/package.json#local-paths)
in the `package.json` of JavaScript projects. The dependency scan outputs the following error for
such references:

```plaintext
ERROR: Could not find dependencies: <dependency-name>. You may need to run npm install
```

As a workaround, remove the [`retire.js`](analyzers.md#selecting-specific-analyzers) analyzer from
[DS_DEFAULT_ANALYZERS](#configuring-dependency-scanning).

## Troubleshooting

### `Error response from daemon: error processing tar file: docker-tar: relocation error`

This error occurs when the Docker version that runs the dependency scanning job is `19.03.00`.
Consider updating to Docker `19.03.1` or greater. Older versions are not
affected. Read more in
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/13830#note_211354992 "Current SAST container fails").

### Getting warning message `gl-dependency-scanning-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../ci/pipelines/job_artifacts.md#error-message-no-files-to-upload).

### Limitation when using rules:exists

The [dependency scanning CI template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml)
uses the [`rules:exists`](../../../ci/yaml/README.md#rulesexists)
syntax. This directive is limited to 10000 checks and always returns `true` after reaching this
number. Because of this, and depending on the number of files in your repository, a dependency
scanning job might be triggered even if the scanner doesn't support your project.
