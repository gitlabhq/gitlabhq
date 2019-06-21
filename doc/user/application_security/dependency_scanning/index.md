# Dependency Scanning **[ULTIMATE]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/5105)
in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.7.

## Overview

If you are using [GitLab CI/CD](../../../ci/README.md), you can analyze your dependencies for known
vulnerabilities using Dependency Scanning.

You can take advantage of Dependency Scanning by either [including the CI job](#including-the-provided-template)
in your existing `.gitlab-ci.yml` file or by implicitly using
[Auto Dependency Scanning](../../../topics/autodevops/index.md#auto-dependency-scanning-ultimate)
that is provided by [Auto DevOps](../../../topics/autodevops/index.md).

GitLab checks the Dependency Scanning report, compares the found vulnerabilities
between the source and target branches, and shows the information right on the
merge request.

![Dependency Scanning Widget](img/dependency_scanning.png)

The results are sorted by the severity of the vulnerability:

1. Critical
1. High
1. Medium
1. Low
1. Unknown
1. Everything else

## Use cases

It helps to automatically find security vulnerabilities in your dependencies
while you are developing and testing your applications. For example when your
application is using an external (open source) library which is known to be vulnerable.

## Requirements

To run a Dependency Scanning job, you need GitLab Runner with the
[`docker`](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html#running-privileged-containers-for-the-runners)
executor running in privileged mode. If you're using the shared Runners on GitLab.com,
this is enabled by default.

## Supported languages and package managers

The following languages and dependency managers are supported.

| Language (package managers)                                                 | Scan tool                                                                                                                         |
|-----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| JavaScript ([npm](https://www.npmjs.com/), [yarn](https://yarnpkg.com/en/)) | [gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium/general), [Retire.js](https://retirejs.github.io/retire.js)         |
| Python ([pip](https://pip.pypa.io/en/stable/)) (only `requirements.txt` supported)  | [gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium/general)                                                            |
| Ruby ([gem](https://rubygems.org/))                                         | [gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium/general), [bundler-audit](https://github.com/rubysec/bundler-audit) |
| Java ([Maven](https://maven.apache.org/))                                   | [gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium/general)                                                            |
| PHP ([Composer](https://getcomposer.org/))                                  | [gemnasium](https://gitlab.com/gitlab-org/security-products/gemnasium/general)                                                            |

Some scanners require to send a list of project dependencies to GitLab's central
servers to check for vulnerabilities. To learn more about this or to disable it,
refer to the [GitLab Dependency Scanning tool documentation](https://gitlab.com/gitlab-org/security-products/dependency-scanning#remote-checks).

## Configuring Dependency Scanning

To enable Dependency Scanning in your project, define a job in your `.gitlab-ci.yml`
file that generates the
[Dependency Scanning report artifact](../../../ci/yaml/README.md#artifactsreportsdependency_scanning-ultimate).

This can be done in two ways:

- For GitLab 11.9 and later, including the provided `Dependency-Scanning.gitlab-ci.yml` template (recommended).
- Manually specifying the job definition. Not recommended unless using GitLab
  11.8 and earlier.

### Including the provided template

NOTE: **Note:**
The CI/CD Dependency Scanning template is supported on GitLab 11.9 and later versions.
For earlier versions, use the [manual job definition](#manual-job-definition-for-gitlab-115-and-later).

A CI/CD [Dependency Scanning template](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml)
with the default Dependency Scanning job definition is provided as a part of your GitLab
installation which you can [include](../../../ci/yaml/README.md#includetemplate)
in your `.gitlab-ci.yml` file.

To enable Dependency Scanning using the provided template, add the following to
your `.gitlab-ci.yml` file:

```yaml
include:
  template: Dependency-Scanning.gitlab-ci.yml
```

The included template will create a `dependency_scanning` job in your CI/CD
pipeline and scan your project's source code for possible vulnerabilities.

The report will be saved as a
[Dependency Scanning report artifact](../../../ci/yaml/README.md#artifactsreportsdependency_scanning-ultimate)
that you can later download and analyze. Due to implementation limitations, we
always take the latest Dependency Scanning artifact available.

Some security scanners require to send a list of project dependencies to GitLab
central servers to check for vulnerabilities. To learn more about this or to
disable it, check the
[GitLab Dependency Scanning tool documentation](https://gitlab.com/gitlab-org/security-products/dependency-scanning#remote-checks).

#### Customizing the Dependency Scanning settings

The Dependency Scanning settings can be changed through environment variables by using the
[`variables`](../../../ci/yaml/README.md#variables) parameter in `.gitlab-ci.yml`.
These variables are documented in the
[Dependency Scanning tool documentation](https://gitlab.com/gitlab-org/security-products/dependency-scanning#settings).

For example:

```yaml
include:
  template: Dependency-Scanning.gitlab-ci.yml

variables:
  DEP_SCAN_DISABLE_REMOTE_CHECKS: true
```

Because template is [evaluated before](../../../ci/yaml/README.md#include) the pipeline
configuration, the last mention of the variable will take precedence.

#### Overriding the Dependency Scanning template

If you want to override the job definition (for example, change properties like
`variables` or `dependencies`), you need to declare a `dependency_scanning` job
after the template inclusion and specify any additional keys under it. For example:

```yaml
include:
  template: Dependency-Scanning.gitlab-ci.yml

dependency_scanning:
  variables:
    CI_DEBUG_TRACE: "true"
```

### Manual job definition for GitLab 11.5 and later

For GitLab 11.5 and GitLab Runner 11.5 and later, the following `dependency_scanning`
job can be added:

```yaml
dependency_scanning:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - export DS_VERSION=${SP_VERSION:-$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')}
    - |
      docker run \
      --env DS_ANALYZER_IMAGES \
      --env DS_ANALYZER_IMAGE_PREFIX \
      --env DS_ANALYZER_IMAGE_TAG \
      --env DS_DEFAULT_ANALYZERS \
      --env DEP_SCAN_DISABLE_REMOTE_CHECKS \
      --env DS_DOCKER_CLIENT_NEGOTIATION_TIMEOUT \
      --env DS_PULL_ANALYZER_IMAGE_TIMEOUT \
      --env DS_RUN_ANALYZER_TIMEOUT \
      --volume "$PWD:/code" \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      "registry.gitlab.com/gitlab-org/security-products/dependency-scanning:$DS_VERSION" /code
  dependencies: []
  artifacts:
    reports:
      dependency_scanning: gl-dependency-scanning-report.json
```

You can supply many other [settings variables](https://gitlab.com/gitlab-org/security-products/dependency-scanning#settings)
via `docker run --env` to customize your job execution.

### Manual job definition for GitLab 11.4 and earlier (deprecated)

CAUTION: **Caution:**
Before GitLab 11.5, the Dependency Scanning job and artifact had to be named specifically
to automatically extract the report data and show it in the merge request widget.
While these old job definitions are still maintained, they have been deprecated
and may be removed in the next major release, GitLab 12.0. You are strongly advised
to update your current `.gitlab-ci.yml` configuration to reflect that change.

For GitLab 11.4 and earlier, the job should look like:

```yaml
dependency_scanning:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - export DS_VERSION=${SP_VERSION:-$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')}
    - |
      docker run \
      --env DS_ANALYZER_IMAGES \
      --env DS_ANALYZER_IMAGE_PREFIX \
      --env DS_ANALYZER_IMAGE_TAG \
      --env DS_DEFAULT_ANALYZERS \
      --env DS_EXCLUDED_PATHS \
      --env DEP_SCAN_DISABLE_REMOTE_CHECKS \
      --env DS_DOCKER_CLIENT_NEGOTIATION_TIMEOUT \
      --env DS_PULL_ANALYZER_IMAGE_TIMEOUT \
      --env DS_RUN_ANALYZER_TIMEOUT \
      --volume "$PWD:/code" \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      "registry.gitlab.com/gitlab-org/security-products/dependency-scanning:$DS_VERSION" /code
  artifacts:
    paths: [gl-dependency-scanning-report.json]
```

## Reports JSON format

CAUTION: **Caution:**
The JSON report artifacts are not a public API of Dependency Scanning and their format may change in future.

The Dependency Scanning tool emits a JSON report file. Here is an example of the report structure with all important parts of
it highlighted:

```json-doc
{
  "version": "2.0",
  "vulnerabilities": [
    {
      "category": "dependency_scanning",
      "name": "Regular Expression Denial of Service",
      "message": "Regular Expression Denial of Service in debug",
      "description": "The debug module is vulnerable to regular expression denial of service when untrusted user input is passed into the `o` formatter. It takes around 50k characters to block for 2 seconds making this a low severity issue.",
      "cve": "yarn.lock:debug:gemnasium:37283ed4-0380-40d7-ada7-2d994afcc62a",
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
      "category": "dependency_scanning",
      "name": "Authentication bypass via incorrect DOM traversal and canonicalization",
      "message": "Authentication bypass via incorrect DOM traversal and canonicalization in saml2-js",
      "description": "Some XML DOM traversal and canonicalization APIs may be inconsistent in handling of comments within XML nodes. Incorrect use of these APIs by some SAML libraries results in incorrect parsing of the inner text of XML nodes such that any inner text after the comment is lost prior to cryptographically signing the SAML message. Text after the comment therefore has no impact on the signature on the SAML message.\r\n\r\nA remote attacker can modify SAML content for a SAML service provider without invalidating the cryptographic signature, which may allow attackers to bypass primary authentication for the affected SAML service provider.",
      "cve": "yarn.lock:saml2-js:gemnasium:9952e574-7b5b-46fa-a270-aeb694198a98",
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
          "cve": "yarn.lock:saml2-js:gemnasium:9952e574-7b5b-46fa-a270-aeb694198a98"
        }
      ],
      "summary": "Upgrade saml2-js",
      "diff": "ZGlmZiAtLWdpdCBhL...OR0d1ZUc2THh3UT09Cg==" // some content is omitted for brevity
    }
  ]
}
```

Here is the description of the report file structure nodes and their meaning. All fields are mandatory to be present in
the report JSON unless stated otherwise. Presence of optional fields depends on the underlying analyzers being used.

| Report JSON node                                     | Function |
|------------------------------------------------------|----------|
| `version`                                            | Report syntax version used to generate this JSON. |
| `vulnerabilities`                                    | Array of vulnerability objects. |
| `vulnerabilities[].category`                         | Where this vulnerability belongs (SAST, Dependency Scanning etc.). For Dependency Scanning, it will always be `dependency_scanning`. |
| `vulnerabilities[].name`                             | Name of the vulnerability, this must not include the occurrence's specific information. Optional. |
| `vulnerabilities[].message`                          | A short text that describes the vulnerability, it may include occurrence's specific information. Optional. |
| `vulnerabilities[].description`                      | A long text that describes the vulnerability. Optional. |
| `vulnerabilities[].cve`                              | A fingerprint string value that represents a concrete occurrence of the vulnerability. It's used to determine whether two vulnerability occurrences are same or different. May not be 100% accurate. **This is NOT a [CVE](https://cve.mitre.org/)**. |
| `vulnerabilities[].severity`                         | How much the vulnerability impacts the software. Possible values: `Undefined` (an analyzer has not provided this info), `Info`, `Unknown`, `Low`, `Medium`, `High`, `Critical`. |
| `vulnerabilities[].confidence`                       | How reliable the vulnerability's assessment is. Possible values: `Undefined` (an analyzer has not provided this info), `Ignore`, `Unknown`, `Experimental`, `Low`, `Medium`, `High`, `Confirmed`. |
| `vulnerabilities[].solution`                         | Explanation of how to fix the vulnerability. Optional. |
| `vulnerabilities[].scanner`                          | A node that describes the analyzer used to find this vulnerability. |
| `vulnerabilities[].scanner.id`                       | Id of the scanner as a snake_case string. |
| `vulnerabilities[].scanner.name`                     | Name of the scanner, for display purposes. |
| `vulnerabilities[].location`                         | A node that tells where the vulnerability is located. |
| `vulnerabilities[].location.file`                    | Path to the dependencies file (e.g., `yarn.lock`). Optional. |
| `vulnerabilities[].location.dependency`              | A node that describes the dependency of a project where the vulnerability is located. |
| `vulnerabilities[].location.dependency.package`      | A node that provides the information on the package where the vulnerability is located. |
| `vulnerabilities[].location.dependency.package.name` | Name of the package where the vulnerability is located. Optional. |
| `vulnerabilities[].location.dependency.version`      | Version of the vulnerable package. Optional. |
| `vulnerabilities[].identifiers`                      | An ordered array of references that identify a vulnerability on internal or external DBs. |
| `vulnerabilities[].identifiers[].type`               | Type of the identifier. Possible values: common identifier types (among `cve`, `cwe`, `osvdb`, and `usn`) or analyzer-dependent ones (e.g. `gemnasium` for [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/)). |
| `vulnerabilities[].identifiers[].name`               | Name of the identifier for display purpose. |
| `vulnerabilities[].identifiers[].value`              | Value of the identifier for matching purpose. |
| `vulnerabilities[].identifiers[].url`                | URL to identifier's documentation. Optional. |
| `vulnerabilities[].links`                            | An array of references to external documentation pieces or articles that describe the vulnerability further. Optional. |
| `vulnerabilities[].links[].name`                     | Name of the vulnerability details link. Optional. |
| `vulnerabilities[].links[].url`                      | URL of the vulnerability details document. Optional. |
| `remediations`                                       | An array of objects containing information on cured vulnerabilities along with patch diffs to apply. Empty if no remediations provided by an underlying analyzer. |
| `remediations[].fixes`                               | An array of strings that represent references to vulnerabilities fixed by this particular remediation. |
| `remediations[].fixes[].cve`                         | A string value that describes a fixed vulnerability occurrence in the same format as `vulnerabilities[].cve`. |
| `remediations[].summary`                             | Overview of how the vulnerabilities have been fixed. |
| `remediations[].diff`                                | base64-encoded remediation code diff, compatible with [`git apply`](https://git-scm.com/docs/git-format-patch#_discussion). |

## Security Dashboard

The Security Dashboard is a good place to get an overview of all the security
vulnerabilities in your groups and projects. Read more about the
[Security Dashboard](../security_dashboard/index.md).

## Interacting with the vulnerabilities

Once a vulnerability is found, you can interact with it. Read more on how to
[interact with the vulnerabilities](../index.md#interacting-with-the-vulnerabilities).

## Dependency List

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/10075) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.0.

An additional benefit of Dependency Scanning is the ability to get a list of your
project's dependencies with their versions. This list can be generated only for
[languages and package managers](#supported-languages-and-package-managers)
supported by Gemnasium.

To see the generated dependency list, navigate to your project's **Project > Dependency List**.

## Contributing to the vulnerability database

You can search the [gemnasium-db](https://gitlab.com/gitlab-org/security-products/gemnasium-db) project
to find a vulnerability in the Gemnasium database.
You can also [submit new vulnerabilities](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md).
