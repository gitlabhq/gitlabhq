---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Static Application Security Testing (SAST) **(FREE)**

> All open source (OSS) analyzers were moved from GitLab Ultimate to GitLab Free in GitLab 13.3.

NOTE:
The whitepaper ["A Seismic Shift in Application Security"](https://about.gitlab.com/resources/whitepaper-seismic-shift-application-security/)
explains how 4 of the top 6 attacks were application based. Download it to learn how to protect your
organization.

If you're using [GitLab CI/CD](../../../ci/index.md), you can use Static Application Security
Testing (SAST) to check your source code for known vulnerabilities. You can run SAST analyzers in
any GitLab tier. The analyzers output JSON-formatted reports as job artifacts.

With GitLab Ultimate, SAST results are also processed so you can:

- See them in merge requests.
- Use them in approval workflows.
- Review them in the security dashboard.

For more details, see the [Summary of features per tier](#summary-of-features-per-tier).

![SAST results shown in the MR widget](img/sast_results_in_mr_v14_0.png)

The results are sorted by the priority of the vulnerability:

<!-- vale gitlab.SubstitutionWarning = NO -->

1. Critical
1. High
1. Medium
1. Low
1. Info
1. Unknown

<!-- vale gitlab.SubstitutionWarning = YES -->

A pipeline consists of multiple jobs, including SAST and DAST scanning. If any job fails to finish
for any reason, the security dashboard does not show SAST scanner output. For example, if the SAST
job finishes but the DAST job fails, the security dashboard does not show SAST results. On failure,
the analyzer outputs an [exit code](../../../development/integrations/secure.md#exit-code).

## Use cases

- Your code has a potentially dangerous attribute in a class, or unsafe code
  that can lead to unintended code execution.
- Your application is vulnerable to cross-site scripting (XSS) attacks that can
  be leveraged to unauthorized access to session data.

## Requirements

SAST runs in the `test` stage, which is available by default. If you redefine the stages in the `.gitlab-ci.yml` file, the `test` stage is required.

To run SAST jobs, by default, you need GitLab Runner with the
[`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
If you're using the shared runners on GitLab.com, this is enabled by default.

WARNING:
Our SAST jobs require a Linux/amd64 container type. Windows containers are not yet supported.

WARNING:
If you use your own runners, make sure the Docker version installed
is **not** `19.03.0`. See [troubleshooting information](#error-response-from-daemon-error-processing-tar-file-docker-tar-relocation-error) for details.

## Supported languages and frameworks

GitLab SAST supports a variety of languages, package managers, and frameworks. Our SAST security scanners also feature automatic language detection which works even for mixed-language projects. If any supported language is detected in project source code we automatically run the appropriate SAST analyzers.

You can also [view our language roadmap](https://about.gitlab.com/direction/secure/static-analysis/sast/#language-support) and [request other language support by opening an issue](https://gitlab.com/groups/gitlab-org/-/epics/297).

| Language (package managers) / framework        | Scan tool                                                                                                 | Introduced in GitLab Version                                                            |
|------------------------------------------------|-----------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| .NET Core                                      | [Security Code Scan](https://security-code-scan.github.io)                                                | 11.0                                                                                    |
| .NET Framework<sup>1</sup>                     | [Security Code Scan](https://security-code-scan.github.io)                                                | 13.0                                                                                    |
| Apex (Salesforce)                              | [PMD](https://pmd.github.io/pmd/index.html)                                                               | 12.1                                                                                    |
| C                                              | [Semgrep](https://semgrep.dev)                                                                            | 14.2                                                                                    |
| C/C++                                          | [Flawfinder](https://github.com/david-a-wheeler/flawfinder)                                               | 10.7                                                                                    |
| Elixir (Phoenix)                               | [Sobelow](https://github.com/nccgroup/sobelow)                                                            | 11.1                                                                                    |
| Go                                             | [Gosec](https://github.com/securego/gosec)                                                                | 10.7                                                                                    |
| Go                                             | [Semgrep](https://semgrep.dev)                                                                            | 14.4                                                                                    |
| Groovy<sup>2</sup>                             | [SpotBugs](https://spotbugs.github.io/) with the [find-sec-bugs](https://find-sec-bugs.github.io/) plugin | 11.3 (Gradle) & 11.9 (Ant, Maven, SBT)                                                  |
| Helm Charts                                    | [Kubesec](https://github.com/controlplaneio/kubesec)                                                      | 13.1                                                                                    |
| Java (any build system)                        | [Semgrep](https://semgrep.dev)                                                                            | 14.10                                                                                   |
| Java<sup>2</sup>                               | [SpotBugs](https://spotbugs.github.io/) with the [find-sec-bugs](https://find-sec-bugs.github.io/) plugin | 10.6 (Maven), 10.8 (Gradle) & 11.9 (Ant, SBT)                                           |
| Java (Android)                                 | [MobSF (beta)](https://github.com/MobSF/Mobile-Security-Framework-MobSF)                                  | 13.5                                                                                    |
| JavaScript                                     | [ESLint security plugin](https://github.com/nodesecurity/eslint-plugin-security)                          | 11.8                                                                                    |
| JavaScript                                     | [Semgrep](https://semgrep.dev)                                                                            | 13.10                                                                                   |
| Kotlin (Android)                               | [MobSF (beta)](https://github.com/MobSF/Mobile-Security-Framework-MobSF)                                  | 13.5                                                                                    |
| Kotlin (General)<sup>2</sup>                   | [SpotBugs](https://spotbugs.github.io/) with the [find-sec-bugs](https://find-sec-bugs.github.io/) plugin | 13.11                                                                                   |
| Kubernetes manifests                           | [Kubesec](https://github.com/controlplaneio/kubesec)                                                      | 12.6                                                                                    |
| Node.js                                        | [NodeJsScan](https://github.com/ajinabraham/NodeJsScan)                                                   | 11.1                                                                                    |
| Objective-C (iOS)                              | [MobSF (beta)](https://github.com/MobSF/Mobile-Security-Framework-MobSF)                                  | 13.5                                                                                    |
| PHP                                            | [phpcs-security-audit](https://github.com/FloeDesignTechnologies/phpcs-security-audit)                    | 10.8                                                                                    |
| Python ([pip](https://pip.pypa.io/en/stable/)) | [bandit](https://github.com/PyCQA/bandit)                                                                 | 10.3                                                                                    |
| Python                                         | [Semgrep](https://semgrep.dev)                                                                            | 13.9                                                                                    |
| React                                          | [ESLint react plugin](https://github.com/yannickcr/eslint-plugin-react)                                   | 12.5                                                                                    |
| React                                          | [Semgrep](https://semgrep.dev)                                                                            | 13.10                                                                                   |
| Ruby                                           | [brakeman](https://brakemanscanner.org)                                                                   | 13.9                                                                                    |
| Ruby on Rails                                  | [brakeman](https://brakemanscanner.org)                                                                   | 10.3                                                                                    |
| Scala<sup>2</sup>                              | [SpotBugs](https://spotbugs.github.io/) with the [find-sec-bugs](https://find-sec-bugs.github.io/) plugin | 11.0 (SBT) & 11.9 (Ant, Gradle, Maven)                                                  |
| Swift (iOS)                                    | [MobSF (beta)](https://github.com/MobSF/Mobile-Security-Framework-MobSF)                                  | 13.5                                                                                    |
| TypeScript                                     | [ESLint security plugin](https://github.com/nodesecurity/eslint-plugin-security)                          | 11.9, [merged](https://gitlab.com/gitlab-org/gitlab/-/issues/36059) with ESLint in 13.2 |
| TypeScript                                     | [Semgrep](https://semgrep.dev)                                                                            | 13.10                                                                                   |

1. .NET 4 support is limited. The analyzer runs in a Linux container and does not have access to Windows-specific libraries or features. We currently plan to [migrate C# coverage to Semgrep-based scanning](https://gitlab.com/gitlab-org/gitlab/-/issues/347258) to make it easier to scan C# projects.
1. The SpotBugs-based analyzer supports [Ant](https://ant.apache.org/), [Gradle](https://gradle.org/), [Maven](https://maven.apache.org/), and [SBT](https://www.scala-sbt.org/). It can also be used with variants like the
[Gradle wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html),
[Grails](https://grails.org/),
and the [Maven wrapper](https://github.com/takari/maven-wrapper).

### Multi-project support

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4895) in GitLab 13.7.

GitLab SAST can scan repositories that contain multiple projects.

The following analyzers have multi-project support:

- Bandit
- ESLint
- Gosec
- Kubesec
- NodeJsScan
- MobSF
- PMD
- Security Code Scan
- Semgrep
- SpotBugs
- Sobelow

#### Enable multi-project support for Security Code Scan

Multi-project support in the Security Code Scan requires a Solution (`.sln`) file in the root of
the repository. For details on the Solution format, see the Microsoft reference [Solution (`.sln`) file](https://docs.microsoft.com/en-us/visualstudio/extensibility/internals/solution-dot-sln-file?view=vs-2019).

### Supported distributions

The default scanner images are build off a base Alpine image for size and maintainability.

#### FIPS-enabled images

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6479) in GitLab 14.10.

GitLab offers an image version, based on the [Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) base image,
that uses a FIPS 140-validated cryptographic module. To use the FIPS-enabled image, you can either:

- Set the `SAST_IMAGE_SUFFIX` to `-fips`.
- Add the `-fips` extension to the default image name.

For example:

```yaml
variables:
  SAST_IMAGE_SUFFIX: '-fips'

include:
  - template: Security/SAST.gitlab-ci.yml
```

A FIPS-compliant image is only available for the Semgrep-based analyzer.

To use SAST in a FIPS-compliant manner, you must [exclude other analyzers from running](analyzers.md#customize-analyzers).

### Making SAST analyzers available to all GitLab tiers

All open source (OSS) analyzers have been moved to the GitLab Free tier as of GitLab 13.3.

#### Summary of features per tier

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/),
as shown in the following table:

| Capability                                                      | In Free & Premium   | In Ultimate        |
|:----------------------------------------------------------------|:--------------------|:-------------------|
| [Configure SAST scanners](#configuration)                       | **{check-circle}**  | **{check-circle}** |
| [Customize SAST settings](#available-cicd-variables)            | **{check-circle}**  | **{check-circle}** |
| Download [JSON Report](#reports-json-format)                    | **{check-circle}**  | **{check-circle}** |
| See new findings in merge request widget                        | **{dotted-circle}** | **{check-circle}** |
| [Manage vulnerabilities](../vulnerabilities/index.md)           | **{dotted-circle}** | **{check-circle}** |
| [Access the Security Dashboard](../security_dashboard/index.md) | **{dotted-circle}** | **{check-circle}** |
| [Configure SAST in the UI](#configure-sast-in-the-ui)           | **{dotted-circle}** | **{check-circle}** |
| [Customize SAST rulesets](#customize-rulesets)                  | **{dotted-circle}** | **{check-circle}** |
| [Detect False Positives](#false-positive-detection)             | **{dotted-circle}** | **{check-circle}** |
| [Track moved vulnerabilities](#advanced-vulnerability-tracking) | **{dotted-circle}** | **{check-circle}** |

## Contribute your scanner

The [Security Scanner Integration](../../../development/integrations/secure.md) documentation explains how to integrate other security scanners into GitLab.

## Configuration

To configure SAST for a project you can:

- Use [Auto SAST](../../../topics/autodevops/stages.md#auto-sast), provided by
  [Auto DevOps](../../../topics/autodevops/index.md).
- [Configure SAST manually](#configure-sast-manually).
- [Configure SAST using the UI](#configure-sast-in-the-ui) (introduced in GitLab 13.3).

### Configure SAST manually

To enable SAST you must [include](../../../ci/yaml/index.md#includetemplate)
the [`SAST.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)
provided as a part of your GitLab installation.

Add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
```

The included template creates SAST jobs in your CI/CD pipeline and scans
your project's source code for possible vulnerabilities.

The results are saved as a
[SAST report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportssast)
that you can later download and analyze. Due to implementation limitations, we
always take the latest SAST artifact available.

### Configure SAST in the UI

You can enable and configure SAST in the UI, either with default settings, or with customizations.
The method you can use depends on your GitLab license tier.

- [Configure SAST in the UI with default settings](#configure-sast-in-the-ui-with-default-settings).
- [Configure SAST in the UI with customizations](#configure-sast-in-the-ui-with-customizations). **(ULTIMATE)**

### Configure SAST in the UI with default settings

> [Introduced](https://about.gitlab.com/releases/2021/02/22/gitlab-13-9-released/#security-configuration-page-for-all-users) in GitLab 13.9

NOTE:
The configuration tool works best with no existing `.gitlab-ci.yml` file, or with a minimal
configuration file. If you have a complex GitLab configuration file it may not be parsed
successfully, and an error may occur.

To enable and configure SAST with default settings:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance** > **Configuration**.
1. In the SAST section, select **Configure with a merge request**.
1. Review and merge the merge request to enable SAST.

Pipelines now include a SAST job.

### Configure SAST in the UI with customizations **(ULTIMATE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3659) in GitLab 13.3.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/232862) in GitLab 13.4.
> - [Improved](https://gitlab.com/groups/gitlab-org/-/epics/3635) in GitLab 13.5.

NOTE:
The configuration tool works best with no existing `.gitlab-ci.yml` file, or with a minimal
configuration file. If you have a complex GitLab configuration file it may not be parsed
successfully, and an error may occur.

To enable and configure SAST with customizations:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Configuration**.
1. If the project does not have a `.gitlab-ci.yml` file, select **Enable SAST** in the Static
   Application Security Testing (SAST) row, otherwise select **Configure SAST**.
1. Enter the custom SAST values.

   Custom values are stored in the `.gitlab-ci.yml` file. For CI/CD variables not in the SAST
   Configuration page, their values are inherited from the GitLab SAST template.

1. Optionally, expand the **SAST analyzers** section, select individual
   [SAST analyzers](analyzers.md) and enter custom analyzer values.
1. Select **Create Merge Request**.
1. Review and merge the merge request.

Pipelines now include a SAST job.

### Overriding SAST jobs

WARNING:
Beginning in GitLab 13.0, the use of [`only` and `except`](../../../ci/yaml/index.md#only--except)
is no longer supported. When overriding the template, you must use [`rules`](../../../ci/yaml/index.md#rules) instead.

To override a job definition, (for example, change properties like `variables` or `dependencies`),
declare a job with the same name as the SAST job to override. Place this new job after the template
inclusion and specify any additional keys under it. For example, this enables `FAIL_NEVER` for the
`spotbugs` analyzer:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

spotbugs-sast:
  variables:
    FAIL_NEVER: 1
```

#### Pinning to minor image version

While our templates use `MAJOR` version pinning to always ensure the latest analyzer
versions are pulled, there are certain cases where it can be beneficial to pin
an analyzer to a specific release. To do so, override the `SAST_ANALYZER_IMAGE_TAG` CI/CD variable
in the job template directly.

In the example below, we pin to a minor version of the `semgrep` analyzer and a specific patch version of the `brakeman` analyzer:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

semgrep-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "2.16"

brakeman-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "2.21.1"
```

### Customize rulesets **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/235382) in GitLab 13.5.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/339614) support for
>   passthrough chains. Expanded to include additional passthrough types of `file`, `git`, and `url` in GitLab 14.6.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/235359) support for overriding rules in GitLab 14.8.

You can customize the default scanning rules provided by our SAST analyzers.
Ruleset customization supports the following that can be used
simultaneously:

- [Disabling predefined rules](index.md#disable-predefined-analyzer-rules). Available for all analyzers.
- [Overriding predefined rules](index.md#override-predefined-analyzer-rules). Available for all analyzers.
- Modifying the default behavior of a given analyzer by [synthesizing and passing a custom configuration](index.md#synthesize-a-custom-configuration). Available for only `nodejs-scan`, `gosec`, and `semgrep`.

To customize the default scanning rules, create a file containing custom rules. These rules
are passed through to the analyzer's underlying scanner tools.

To create a custom ruleset:

1. Create a `.gitlab` directory at the root of your project, if one doesn't already exist.
1. Create a custom ruleset file named `sast-ruleset.toml` in the `.gitlab` directory.

#### Disable predefined analyzer rules

To disable analyzer rules:

1. Set the `disabled` flag to `true` in the context of a `ruleset` section

1. In one or more `ruleset.identifier` sub sections, list the rules that you want disabled. Every `ruleset.identifier` section has:

- a `type` field, to name the predefined rule identifier that the targeted analyzer uses.
- a `value` field, to name the rule to be disabled.

##### Example: Disable predefined rules of SAST analyzers

In the following example, the disabled rules are assigned to `eslint`
and `sobelow` by matching the `type` and `value` of identifiers:

```toml
[eslint]
  [[eslint.ruleset]]
    disable = true
    [eslint.ruleset.identifier]
      type = "eslint_rule_id"
      value = "security/detect-object-injection"

  [[eslint.ruleset]]
    disable = true
    [eslint.ruleset.identifier]
      type = "cwe"
      value = "185"

[sobelow]
  [[sobelow.ruleset]]
    disable = true
    [sobelow.ruleset.identifier]
      type = "sobelow_rule_id"
      value = "sql_injection"
```

Those vulnerabilities containing the provided type and value are now disabled, meaning
they won't be displayed in Merge Request nor the Vulnerability Report.

#### Override predefined analyzer rules

To override analyzer rules:

1. In one or more `ruleset.identifier` subsections, list the rules that you want to override. Every `ruleset.identifier` section has:

   - a `type` field, to name the predefined rule identifier that the targeted analyzer uses.
   - a `value` field, to name the rule to be overridden.

1. In the `ruleset.override` context of a `ruleset` section,
   provide the keys to override. Any combination of keys can be
   overridden. Valid keys are:

   - description
   - message
   - name
   - severity (valid options are: Critical, High, Medium, Low, Unknown, Info)

##### Example: Override predefined rules of SAST analyzers

Before adding a ruleset, we verify which vulnerability will be overwritten by viewing the [`gl-sast-report.json`](#reports-json-format):

```json
"identifiers": [
        {
          "type": "gosec_rule_id",
          "name": "Gosec Rule ID G307",
          "value": "G307"
        },
        {
          "type": "CWE",
          "name": "CWE-703",
          "value": "703",
          "url": "https://cwe.mitre.org/data/definitions/703.html"
        }
      ]
```

In the following example, rules from `gosec` are matched by the `type`
and `value` of identifiers and then overridden:

```toml
[gosec]
  [[gosec.ruleset]]
    [gosec.ruleset.identifier]
        type = "CWE"
        value = "703"
    [gosec.ruleset.override]
      severity = "Critical"
```

If a vulnerability is found with a type `CWE` with a value of `703` then
the vulnerability severity is overwritten to `Critical`.

#### Synthesize a custom configuration

To create a custom configuration, you can use passthrough chains.

A passthrough is a single step in a passthrough chain. The passthrough is evaluated
in a sequence to incrementally build a configuration. The configuration is then
passed to the target analyzer.

A configuration section for an analyzer has the following
parameters:

| Parameter     | Explanation |
| ------------- | ------ |
| `description` | Description about the analyzer configuration section. |
| `targetdir`   | The `targetdir` parameter defines the directory where the final configuration is located. If `targetdir` is empty, the analyzer uses a random directory. The maximum size of `targetdir` is 100MB. |
| `validate`    | If set to `true`, the target files for passthroughs (`raw`, `file` and `url`) are validated. The validation works for `yaml`, `xml`, `json` and `toml` files. The proper validator is identified based on the extension of the target file. By default, `validate` is set to `false`. |
| `interpolate` | If set to `true`, environment variable interpolation is enabled so that the configuration uses secrets/tokens. We advise using this feature with caution to not leak any secrets. By default, `interpolate` is set to `false`. |
| `timeout`     | The total `timeout` for the evaluation of a passthrough chain is set to 60 seconds. If `timeout` is not set, the default timeout is 60 seconds. The timeout cannot exceed 300 seconds. |

A configuration section can include one or more passthrough sections. The maximum number of passthrough sections is 20.
There are several types of passthroughs:

| Type   | Description |
| ------ | ------ |
| `file` | Use a file that is already available in the Git repository. |
| `raw`  | Provide the configuration inline. |
| `git`  | Pull the configuration from a remote Git repository. |
| `url`  | Fetch the analyzer configuration through HTTP. |

If multiple passthrough sections are defined in a passthrough chain, their
position in the chain defines the order in which they are evaluated.

- Passthroughs listed later in the chain sequence have a higher precedence.
- Passthroughs with a higher precedence overwrite (default) and append data
  yielded by previous passthroughs. This is useful for cases where you need to
  use or modify an existing configuration.

Configure a passthrough these parameters:

| Parameter     | Explanation |
| ------------ | ----------- |
| `type`       | One of `file`, `raw`, `git` or `url`. |
| `target`     | The target file that contains the data written by the passthrough evaluation. If no value is provided, a random target file is generated. |
| `mode`       | `overwrite`: if `target` exists, overwrites the file; `append`: append to file instead. The default is `overwrite`. |
| `ref`        | This option only applies to the `git` passthrough type and contains the name of the branch or the SHA to be used. |
| `subdir`     | This option only applies to the `git` passthrough type and can be used to only consider a certain subdirectory of the source Git repository. |
| `value`      | For the `file` `url` and `git` types, `value` defines the source location of the file/Git repository; for the `raw` type, `value` carries the raw content to be passed through. |
| `validator`  | Can be used to explicitly invoke validators (`xml`, `yaml`, `json`, `toml`) on the target files after the application of a passthrough. Per default, no validator is set. |

The amount of data generated by a single passthrough is limited to 1MB.

#### Passthrough configuration examples

##### Raw passthrough for nodejs-scan

Define a custom analyzer configuration. In this example, customized rules are
defined for the `nodejs-scan` scanner:

```toml
[nodejs-scan]
  description = 'custom ruleset for nodejs-scan'

  [[nodejs-scan.passthrough]]
    type  = "raw"
    value = '''
- nodejs-extensions:
  - .js

  template-extensions:
  - .new
  - .hbs
  - ''

  ignore-filenames:
- skip.js

  ignore-paths:
  - __MACOSX
  - skip_dir
  - node_modules

  ignore-extensions:
  - .hbs

  ignore-rules:
  - regex_injection_dos
  - pug_jade_template
  - express_xss

'''
```

##### File passthrough for Gosec

Provide the name of the file containing a custom analyzer configuration. In
this example, customized rules for the `gosec` scanner are contained in the
file `gosec-config.json`:

```toml
[gosec]
  description = 'custom ruleset for gosec'

  [[gosec.passthrough]]
    type  = "file"
    value = "gosec-config.json"
```

##### Passthrough chain for Semgrep

In the below example, we generate a custom configuration under the `/sgrules`
target directory with a total `timeout` of 60 seconds.

Several passthrouh types generate a configuration for the target analyzer:

- Two `git` passthrough sections pull the head of branch
  `refs/remotes/origin/test` from the `myrules` Git repository, and revision
  `97f7686` from the `sast-rules` Git repository. From the `sast-rules` Git
  repository, only data from the `go` subdirectory is considered.
  - The `sast-rules` entry has a higher precedence because it appears later in
    the configuration.
  - If there is a filename collision between files in both repositories, files
    from the `sast` repository overwrite files from the `myrules` repository,
    as `sast-rules` has higher precedence.
- The `raw` entry creates a file named `insecure.yml` under `/sgrules`. The
  full path is `/sgrules/insecure.yml`.
- The `url` entry fetches a configuration made available through a URL and
  stores it in the `/sgrules/gosec.yml` file.

Afterwards, Semgrep is invoked with the final configuration located under
`/sgrules`.

```toml
[semgrep]
  description = 'semgrep custom rules configuration'
  targetdir = "/sgrules"
  timeout = 60

  [[semgrep.passthrough]]
    type  = "git"
    value = "https://gitlab.com/user/myrules.git"
    ref = "refs/remotes/origin/test"

  [[semgrep.passthrough]]
    type  = "git"
    value = "https://gitlab.com/gitlab-org/secure/gsoc-sast-vulnerability-rules/playground/sast-rules.git"
    ref = "97f7686db058e2141c0806a477c1e04835c4f395"
    subdir = "go"

  [[semgrep.passthrough]]
    type  = "raw"
    target = "insecure.yml"
    value = """
rules:
- id: "insecure"
  patterns:
  - pattern: "func insecure() {...}"
  message: |
    Insecure function insecure detected
  metadata:
    cwe: "CWE-200: Exposure of Sensitive Information to an Unauthorized Actor"
  severity: "ERROR"
  languages:
  - "go"
    """

  [[semgrep.passthrough]]
    type  = "url"
    value = "https://semgrep.dev/c/p/gosec"
    target = "gosec.yml"
```

##### Interpolation

The code snippet below shows an example configuration that uses an environment
variable `$GITURL` to access a private repositories with a Git URL. The variable contains
a username and token in the `value` field (for example `https://user:token@url`).
It does not explicitly store credentials in the configuration file. To reduce the risk of leaking secrets through created paths and files, use this feature with caution.

```toml
[semgrep]
  description = 'semgrep custom rules configuration'
  targetdir = "/sgrules"
  interpolate = true

  [[semgrep.passthrough]]
    type  = "git"
    value = "$GITURL"
    ref = "refs/remotes/origin/main"
```

##### Configure the append mode for passthroughs

To append data to previous passthroughs, use the `append` mode for the
passthrough types `file`, `url`, and `raw`.

Passthroughs in `override` mode overwrite files
created when preceding passthroughs in the chain find a naming
collision. If `mode` is set to `append`, a passthrough appends data to the
files created by its predecessors instead of overwriting.

In the below Semgrep configuration,`/sgrules/insecure.yml` assembles two passthroughs. The rules are:

- `insecure`
- `secret`

These rules add a search pattern to the analyzer and extends Semgrep capabilities.

For passthrough chains we recommend that you enable validation. To enable validation,
you can either:

- set `validate` to `true`

- set a passthrough `validator` to `xml`, `json`, `yaml`, or `toml`.

```toml
[semgrep]
  description = 'semgrep custom rules configuration'
  targetdir = "/sgrules"
  validate = true

  [[semgrep.passthrough]]
    type  = "raw"
    target = "insecure.yml"
    value = """
rules:
- id: "insecure"
  patterns:
  - pattern: "func insecure() {...}"
  message: |
    Insecure function insecure detected
  metadata:
    cwe: "...
  severity: "ERROR"
  languages:
  - "go"
"""

  [[semgrep.passthrough]]
    type  = "raw"
    mode  = "append"
    target = "insecure.yml"
    value = """
- id: "secret"
  patterns:
  - pattern-either:
    - pattern: "$MASK = \"...\""
  - metavariable-regex:
      metavariable: "$MASK"
      regex: "(password|pass|passwd|pwd|secret|token)"
  message: |
    Use of Hard-coded Password
    cwe: "..."
  severity: "ERROR"
  languages:
  - "go"
"""
```

### False Positive Detection **(ULTIMATE)**

> Introduced in GitLab 14.2.

Vulnerabilities that have been detected and are false positives will be flagged as false positives in the security dashboard.

False positive detection is available in a subset of the [supported languages](#supported-languages-and-frameworks) and [analyzers](analyzers.md):

- Ruby, in the Brakeman-based analyzer

### Advanced vulnerability tracking **(ULTIMATE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5144) in GitLab 14.2.

Source code is volatile; as developers make changes, source code may move within files or between files.
Security analyzers may have already reported vulnerabilities that are being tracked in the [Vulnerability Report](../vulnerability_report/).
These vulnerabilities are linked to specific problematic code fragments so that they can be found and fixed.
If the code fragments are not tracked reliably as they move, vulnerability management is harder because the same vulnerability could be reported again.

GitLab SAST uses an advanced vulnerability tracking algorithm to more accurately identify when the same vulnerability has moved within a file due to refactoring or unrelated changes.

Advanced vulnerability tracking is available in a subset of the [supported languages](#supported-languages-and-frameworks) and [analyzers](analyzers.md):

- C, in the Semgrep-based analyzer only
- Go, in the Gosec- and Semgrep-based analyzers
- Java, in the Semgrep-based analyzer only
- JavaScript, in the Semgrep-based analyzer only
- Python, in the Semgrep-based analyzer only
- Ruby, in the Brakeman-based analyzer

Support for more languages and analyzers is tracked in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/5144).

### Using CI/CD variables to pass credentials for private repositories

Some analyzers require downloading the project's dependencies in order to
perform the analysis. In turn, such dependencies may live in private Git
repositories and thus require credentials like username and password to download them.
Depending on the analyzer, such credentials can be provided to
it via [custom CI/CD variables](#custom-cicd-variables).

#### Using a CI/CD variable to pass username and password to a private Go repository

If your Go project depends on private modules, see
[Fetch modules from private projects](../../packages/go_proxy/index.md#fetch-modules-from-private-projects)
for how to provide authentication over HTTPS.

To specify credentials via `~/.netrc` provide a `before_script` containing the following:

```yaml
gosec-sast:
  before_script:
    - |
      cat <<EOF > ~/.netrc
      machine gitlab.com
      login $CI_DEPLOY_USER
      password $CI_DEPLOY_PASSWORD
      EOF
```

#### Using a CI/CD variable to pass username and password to a private Maven repository

If your private Maven repository requires login credentials,
you can use the `MAVEN_CLI_OPTS` CI/CD variable.

Read more on [how to use private Maven repositories](../index.md#using-private-maven-repositories).

### Enabling Kubesec analyzer

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12752) in GitLab 12.6.

You need to set `SCAN_KUBERNETES_MANIFESTS` to `"true"` to enable the
Kubesec analyzer. In `.gitlab-ci.yml`, define:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

variables:
  SCAN_KUBERNETES_MANIFESTS: "true"
```

### Pre-compilation

Most GitLab SAST analyzers directly scan your source code without compiling it first.
However, for technical reasons, some analyzers can only scan compiled code.

By default, these analyzers automatically attempt to fetch dependencies and compile your code so it can be scanned.
Automatic compilation can fail if:

- your project requires custom build configurations.
- you use language versions that aren't built into the analyzer.

To resolve these issues, you can skip the analyzer's compilation step and directly provide artifacts from an earlier stage in your pipeline instead.
This strategy is called _pre-compilation_.

Pre-compilation is available for the analyzers that support the `COMPILE` CI/CD variable.
See [Analyzer settings](#analyzer-settings) for the current list.

To use pre-compilation:

1. Output your project's dependencies to a directory in the project's working directory, then save that directory as an artifact by [setting the `artifacts: paths` configuration](../../../ci/yaml/index.md#artifactspaths).
1. Provide the `COMPILE: "false"` CI/CD variable to the analyzer to disable automatic compilation.
1. Add your compilation stage as a dependency for the analyzer job.

To allow the analyzer to recognize the compiled artifacts, you must explicitly specify the path to
the vendored directory.
This configuration can vary per analyzer. For Maven projects, you can use `MAVEN_REPO_PATH`.
See [Analyzer settings](#analyzer-settings) for the complete list of available options.

The following example pre-compiles a Maven project and provides it to the SpotBugs SAST analyzer:

```yaml
stages:
  - build
  - test

include:
  - template: Security/SAST.gitlab-ci.yml

build:
  image: maven:3.6-jdk-8-slim
  stage: build
  script:
    - mvn package -Dmaven.repo.local=./.m2/repository
  artifacts:
    paths:
      - .m2/
      - target/

spotbugs-sast:
  dependencies:
    - build
  variables:
    MAVEN_REPO_PATH: ./.m2/repository
    COMPILE: "false"
  artifacts:
    reports:
      sast: gl-sast-report.json
```

### Available CI/CD variables

SAST can be configured using the [`variables`](../../../ci/yaml/index.md#variables) parameter in
`.gitlab-ci.yml`.

WARNING:
All customization of GitLab security scanning tools should be tested in a merge request before
merging these changes to the default branch. Failure to do so can give unexpected results,
including a large number of false positives.

The following example includes the SAST template to override the `SAST_GOSEC_LEVEL`
variable to `2`. The template is [evaluated before](../../../ci/yaml/index.md#include) the pipeline
configuration, so the last mention of the variable takes precedence.

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

variables:
  SAST_GOSEC_LEVEL: 2
```

#### Logging level

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10880) in GitLab 13.1.

To control the verbosity of logs, set the `SECURE_LOG_LEVEL` environment variable. Messages of this
logging level or higher are output.

From highest to lowest severity, the logging levels are:

- `fatal`
- `error`
- `warn`
- `info` (default)
- `debug`

#### Custom Certificate Authority

To trust a custom Certificate Authority, set the `ADDITIONAL_CA_CERT_BUNDLE` variable to the bundle
of CA certs that you want to trust in the SAST environment. The `ADDITIONAL_CA_CERT_BUNDLE` value should contain the [text representation of the X.509 PEM public-key certificate](https://tools.ietf.org/html/rfc7468#section-5.1). For example, to configure this value in the `.gitlab-ci.yml` file, use the following:

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

#### Docker images

The following are Docker image-related CI/CD variables.

| CI/CD variable            | Description                                                                                                                           |
|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| `SECURE_ANALYZERS_PREFIX` | Override the name of the Docker registry providing the default images (proxy). Read more about [customizing analyzers](analyzers.md). |
| `SAST_EXCLUDED_ANALYZERS` | Names of default images that should never run. Read more about [customizing analyzers](analyzers.md).                                 |
| `SAST_ANALYZER_IMAGE_TAG` | Override the default version of analyzer image. Read more about [pinning the analyzer image version](#pinning-to-minor-image-version).                                 |
| `SAST_IMAGE_SUFFIX`       | Suffix added to the image name. If set to `-fips`, `FIPS-enabled` images are used for scan. See [FIPS-enabled images](#fips-enabled-images) for more details. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355518) in GitLab 14.10. |

#### Vulnerability filters

Some analyzers make it possible to filter out vulnerabilities under a given threshold.

| CI/CD variable               | Default value            | Description                                                                                                                                                                                                                 |
|------------------------------|--------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `SAST_EXCLUDED_PATHS`        | `spec, test, tests, tmp` | Exclude vulnerabilities from output based on the paths. This is a comma-separated list of patterns. Patterns can be globs, or file or folder paths (for example, `doc,spec`). Parent directories also match patterns. You might need to exclude temporary directories used by your build tool as these can generate false positives. To exclude paths, copy and paste the default excluded paths, then **add** your own paths to be excluded. If you don't specify the default excluded paths, you will override the defaults and _only_ paths you specify will be excluded from the SAST scans. |
| `SEARCH_MAX_DEPTH`           | 4                        | SAST searches the repository to detect the programming languages used, and selects the matching analyzers. Set the value of `SEARCH_MAX_DEPTH` to specify how many directory levels the search phase should span. After the analyzers have been selected, the _entire_ repository is analyzed. |
| `SAST_BANDIT_EXCLUDED_PATHS` |                          | Comma-separated list of paths to exclude from scan. Uses Python's [`fnmatch` syntax](https://docs.python.org/2/library/fnmatch.html); For example: `'*/tests/*, */venv/*'`                                                  |
| `SAST_BRAKEMAN_LEVEL`        | 1                        | Ignore Brakeman vulnerabilities under given confidence level. Integer, 1=Low 3=High.                                                                                                                                        |
| `SAST_FLAWFINDER_LEVEL`      | 1                        | Ignore Flawfinder vulnerabilities under given risk level. Integer, 0=No risk, 5=High risk.                                                                                                                                  |
| `SAST_GOSEC_LEVEL`           | 0                        | Ignore Gosec vulnerabilities under given confidence level. Integer, 0=Undefined, 1=Low, 2=Medium, 3=High.                                                                                                                   |

#### Analyzer settings

Some analyzers can be customized with CI/CD variables.

| CI/CD variable              | Analyzer   | Description                                                                                                                                                                                                                        |
|-----------------------------|------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `SCAN_KUBERNETES_MANIFESTS` | Kubesec    | Set to `"true"` to scan Kubernetes manifests.                                                                                                                                                                                      |
| `KUBESEC_HELM_CHARTS_PATH`  | Kubesec    | Optional path to Helm charts that `helm` uses to generate a Kubernetes manifest that `kubesec` scans. If dependencies are defined, `helm dependency build` should be ran in a `before_script` to fetch the necessary dependencies. |
| `KUBESEC_HELM_OPTIONS`      | Kubesec    | Additional arguments for the `helm` executable.                                                                                                                                                                                    |
| `COMPILE`                   | Gosec, SpotBugs   | Set to `false` to disable project compilation and dependency fetching. [Introduced for `SpotBugs`](https://gitlab.com/gitlab-org/gitlab/-/issues/195252) analyzer in GitLab 13.1 and [`Gosec`](https://gitlab.com/gitlab-org/gitlab/-/issues/330678) analyzer in GitLab 14.0.  |
| `ANT_HOME`                  | SpotBugs   | The `ANT_HOME` variable.                                                                                                                                                                                                           |
| `ANT_PATH`                  | SpotBugs   | Path to the `ant` executable.                                                                                                                                                                                                      |
| `GRADLE_PATH`               | SpotBugs   | Path to the `gradle` executable.                                                                                                                                                                                                   |
| `JAVA_OPTS`                 | SpotBugs   | Additional arguments for the `java` executable.                                                                                                                                                                                    |
| `JAVA_PATH`                 | SpotBugs   | Path to the `java` executable.                                                                                                                                                                                                     |
| `SAST_JAVA_VERSION`         | SpotBugs   | Which Java version to use. [Starting in GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/352549), supported versions are `11` and `17` (default). Before GitLab 15.0, supported versions are `8` (default) and `11`.     |
| `MAVEN_CLI_OPTS`            | SpotBugs   | Additional arguments for the `mvn` or `mvnw` executable.                                                                                                                                                                           |
| `MAVEN_PATH`                | SpotBugs   | Path to the `mvn` executable.                                                                                                                                                                                                      |
| `MAVEN_REPO_PATH`           | SpotBugs   | Path to the Maven local repository (shortcut for the `maven.repo.local` property).                                                                                                                                                 |
| `SBT_PATH`                  | SpotBugs   | Path to the `sbt` executable.                                                                                                                                                                                                      |
| `FAIL_NEVER`                | SpotBugs   | Set to `1` to ignore compilation failure.                                                                                                                                                                                          |
| `SAST_GOSEC_CONFIG`         | Gosec      | **{warning}** **[Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/328301)** in GitLab 14.0 - use custom rulesets instead. Path to configuration for Gosec (optional).                                                                                                                                                                                        |
| `PHPCS_SECURITY_AUDIT_PHP_EXTENSIONS` | phpcs-security-audit | Comma separated list of additional PHP Extensions.                                                                                                                                                             |
| `SAST_DISABLE_BABEL`        | NodeJsScan | **{warning}** **[Removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64025)** in GitLab 13.5 |
| `SAST_SEMGREP_METRICS` | Semgrep | Set to `"false"` to disable sending anonymized scan metrics to [r2c](https://r2c.dev/). Default: `true`. Introduced in GitLab 14.0 from the [confidential issue](../../project/issues/confidential_issues.md) `https://gitlab.com/gitlab-org/gitlab/-/issues/330565`.      |

#### Custom CI/CD variables

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18193) in GitLab 12.5.

In addition to the aforementioned SAST configuration CI/CD variables,
all [custom variables](../../../ci/variables/index.md#custom-cicd-variables) are propagated
to the underlying SAST analyzer images if
[the SAST vendored template](#configuration) is used.

NOTE:
In [GitLab 13.3 and earlier](https://gitlab.com/gitlab-org/gitlab/-/issues/220540),
variables whose names started with the following prefixes are **not** propagated to either the
analyzer containers or SAST Docker container: `DOCKER_`, `CI`, `GITLAB_`, `FF_`, `HOME`, `PWD`,
`OLDPWD`, `PATH`, `SHLVL`, `HOSTNAME`.

### Experimental features

You can receive early access to experimental features. Experimental features might be added,
removed, or promoted to regular features at any time.

Experimental features available are:

- Enable scanning of iOS and Android apps using the [MobSF analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf/).

#### Enable experimental features

To enable experimental features, add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

variables:
  SAST_EXPERIMENTAL_FEATURES: "true"
```

## Reports JSON format

SAST outputs a report file in JSON format. The report file contains details of all found vulnerabilities.
To download the report file, you can either:

- Download the file from the CI/CD pipelines page.
- In the pipelines tab on merge requests, set [`artifacts: paths`](../../../ci/yaml/index.md#artifactspaths) to `gl-sast-report.json`.

For information, see [Download job artifacts](../../../ci/pipelines/job_artifacts.md#download-job-artifacts).

For details of the report file's schema, see
[SAST report file schema](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/sast-report-format.json).

For an example SAST report file, see [`gl-secret-detection-report.json`](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/qa/expect/secrets/gl-secret-detection-report.json) example.

## Running SAST in an offline environment

For self-managed GitLab instances in an environment with limited, restricted, or intermittent access
to external resources through the internet, some adjustments are required for the SAST job to
run successfully. For more information, see [Offline environments](../offline_deployments/index.md).

### Requirements for offline SAST

To use SAST in an offline environment, you need:

- GitLab Runner with the [`docker` or `kubernetes` executor](#requirements).
- A Docker Container Registry with locally available copies of SAST [analyzer](https://gitlab.com/gitlab-org/security-products/analyzers) images.
- Configure certificate checking of packages (optional).

GitLab Runner has a [default `pull_policy` of `always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy),
meaning the runner tries to pull Docker images from the GitLab container registry even if a local
copy is available. The GitLab Runner [`pull_policy` can be set to `if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)
in an offline environment if you prefer using only locally available Docker images. However, we
recommend keeping the pull policy setting to `always` if not in an offline environment, as this
enables the use of updated scanners in your CI/CD pipelines.

### Make GitLab SAST analyzer images available inside your Docker registry

For SAST with all [supported languages and frameworks](#supported-languages-and-frameworks),
import the following default SAST analyzer images from `registry.gitlab.com` into your
[local Docker container registry](../../packages/container_registry/index.md):

```plaintext
registry.gitlab.com/security-products/bandit:2
registry.gitlab.com/security-products/brakeman:2
registry.gitlab.com/security-products/eslint:2
registry.gitlab.com/security-products/flawfinder:2
registry.gitlab.com/security-products/gosec:3
registry.gitlab.com/security-products/kubesec:2
registry.gitlab.com/security-products/nodejs-scan:2
registry.gitlab.com/security-products/phpcs-security-audit:2
registry.gitlab.com/security-products/pmd-apex:2
registry.gitlab.com/security-products/security-code-scan:2
registry.gitlab.com/security-products/semgrep:2
registry.gitlab.com/security-products/sobelow:2
registry.gitlab.com/security-products/spotbugs:2
```

The process for importing Docker images into a local offline Docker registry depends on
**your network security policy**. Please consult your IT staff to find an accepted and approved
process by which external resources can be imported or temporarily accessed. These scanners are [periodically updated](../index.md#vulnerability-scanner-maintenance)
with new definitions, and you may be able to make occasional updates on your own.

For details on saving and transporting Docker images as a file, see Docker's documentation on
[`docker save`](https://docs.docker.com/engine/reference/commandline/save/), [`docker load`](https://docs.docker.com/engine/reference/commandline/load/),
[`docker export`](https://docs.docker.com/engine/reference/commandline/export/), and [`docker import`](https://docs.docker.com/engine/reference/commandline/import/).

#### If support for Custom Certificate Authorities are needed

Support for custom certificate authorities was introduced in the following versions.

| Analyzer               | Version                                                                                                    |
| --------               | -------                                                                                                    |
| `bandit`               | [v2.3.0](https://gitlab.com/gitlab-org/security-products/analyzers/bandit/-/releases/v2.3.0)               |
| `brakeman`             | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman/-/releases/v2.1.0)             |
| `eslint`               | [v2.9.2](https://gitlab.com/gitlab-org/security-products/analyzers/eslint/-/releases/v2.9.2)               |
| `flawfinder`           | [v2.3.0](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder/-/releases/v2.3.0)           |
| `gosec`                | [v2.5.0](https://gitlab.com/gitlab-org/security-products/analyzers/gosec/-/releases/v2.5.0)                |
| `kubesec`              | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec/-/releases/v2.1.0)              |
| `nodejs-scan`          | [v2.9.5](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan/-/releases/v2.9.5)          |
| `phpcs-security-audit` | [v2.8.2](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit/-/releases/v2.8.2) |
| `pmd-apex`             | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex/-/releases/v2.1.0)             |
| `security-code-scan`   | [v2.7.3](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan/-/releases/v2.7.3)   |
| `semgrep`              | [v0.0.1](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/releases/v0.0.1)              |
| `sobelow`              | [v2.2.0](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow/-/releases/v2.2.0)              |
| `spotbugs`             | [v2.7.1](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/releases/v2.7.1)             |

### Set SAST CI/CD variables to use local SAST analyzers

Add the following configuration to your `.gitlab-ci.yml` file. You must replace
`SECURE_ANALYZERS_PREFIX` to refer to your local Docker container registry:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

variables:
  SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
```

The SAST job should now use local copies of the SAST analyzers to scan your code and generate
security reports without requiring internet access.

### Configure certificate checking of packages

If a SAST job invokes a package manager, you must configure its certificate verification. In an
offline environment, certificate verification with an external source is not possible. Either use a
self-signed certificate or disable certificate verification. Refer to the package manager's
documentation for instructions.

## Running SAST in SELinux

By default SAST analyzers are supported in GitLab instances hosted on SELinux. Adding a `before_script` in an [overridden SAST job](#overriding-sast-jobs) may not work as runners hosted on SELinux have restricted permissions.

## Troubleshooting

### SAST debug logging

Increase the [Secure scanner log verbosity](#logging-level) to `debug` in a global CI variable to help troubleshoot SAST jobs.

```yaml
variables:
  SECURE_LOG_LEVEL: "debug"
```

### `Error response from daemon: error processing tar file: docker-tar: relocation error`

This error occurs when the Docker version that runs the SAST job is `19.03.0`.
Consider updating to Docker `19.03.1` or greater. Older versions are not
affected. Read more in
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/13830#note_211354992 "Current SAST container fails").

### Getting warning message `gl-sast-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../ci/pipelines/job_artifacts.md#error-message-no-files-to-upload).

### Error: `sast is used for configuration only, and its script should not be executed`

For information on this, see the [GitLab Secure troubleshooting section](../index.md#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed).

### Limitation when using rules:exists

The [SAST CI template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)
uses the `rules:exists` parameter. For performance reasons, a maximum number of matches are made
against the given glob pattern. If the number of matches exceeds the maximum, the `rules:exists`
parameter returns `true`. Depending on the number of files in your repository, a SAST job might be
triggered even if the scanner doesn't support your project. For more details about this issue, see
the [`rules:exists` documentation](../../../ci/yaml/index.md#rulesexists).

### SpotBugs UTF-8 unmappable character errors

These errors occur when UTF-8 encoding isn't enabled on a SpotBugs build and there are UTF-8
characters in the source code. To fix this error, enable UTF-8 for your project's build tool.

For Gradle builds, add the following to your `build.gradle` file:

```gradle
compileJava.options.encoding = 'UTF-8'
tasks.withType(JavaCompile) {
    options.encoding = 'UTF-8'
}
```

For Maven builds, add the following to your `pom.xml` file:

```xml
<properties>
  <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
</properties>
```

### SpotBugs Error: `Project couldn't be built`

If your job is failing at the build step with the message "Project couldn't be built", it's most likely because your job is asking SpotBugs to build with a tool that isn't part of its default tools. For a list of the SpotBugs default tools, see [SpotBugs' asdf dependencies](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/raw/master/config/.tool-versions).

The solution is to use [pre-compilation](#pre-compilation). Pre-compilation ensures the images required by SpotBugs are available in the job's container.

### Flawfinder encoding error

This occurs when Flawfinder encounters an invalid UTF-8 character. To fix this, convert all source code in your project to UTF-8 character encoding. This can be done with [`cvt2utf`](https://github.com/x1angli/cvt2utf) or [`iconv`](https://www.gnu.org/software/libiconv/documentation/libiconv-1.13/iconv.1.html) either over the entire project or per job using the [`before_script`](../../../ci/yaml/index.md#before_script) feature.

### Semgrep slowness, unexpected results, or other errors

If Semgrep is slow, reports too many false positives or false negatives, crashes, fails, or is otherwise broken, see the Semgrep docs for [troubleshooting GitLab SAST](https://semgrep.dev/docs/troubleshooting/gitlab-sast/).

### SAST job fails with message `strconv.ParseUint: parsing "0.0": invalid syntax`

Invoking Docker-in-Docker is the likely cause of this error. Docker-in-Docker is:

- Disabled by default in GitLab 13.0 and later.
- Unsupported from GitLab 13.4 and later.

Several workarounds are available. From GitLab version 13.0 and later, you must not use
Docker-in-Docker.

#### Workaround 1: Pin analyzer versions (GitLab 12.1 and earlier)

Set the following variables for the SAST job. This pins the analyzer versions to the last known
working version, allowing SAST with Docker-in-Docker to complete as it did previously:

```yaml
sast:
  variables:
    SAST_DEFAULT_ANALYZERS: ""
    SAST_ANALYZER_IMAGES: "registry.gitlab.com/gitlab-org/security-products/analyzers/bandit:2.9.6, registry.gitlab.com/gitlab-org/security-products/analyzers/brakeman:2.11.0, registry.gitlab.com/gitlab-org/security-products/analyzers/eslint:2.10.0, registry.gitlab.com/gitlab-org/security-products/analyzers/flawfinder:2.11.1, registry.gitlab.com/gitlab-org/security-products/analyzers/gosec:2.14.0, registry.gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan:2.11.0, registry.gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit:2.9.1, registry.gitlab.com/gitlab-org/security-products/analyzers/pmd-apex:2.9.0, registry.gitlab.com/gitlab-org/security-products/analyzers/secrets:3.12.0, registry.gitlab.com/gitlab-org/security-products/analyzers/security-code-scan:2.13.0, registry.gitlab.com/gitlab-org/security-products/analyzers/sobelow:2.8.0, registry.gitlab.com/gitlab-org/security-products/analyzers/spotbugs:2.13.6, registry.gitlab.com/gitlab-org/security-products/analyzers/tslint:2.4.0"
```

Remove any analyzers you don't need from the `SAST_ANALYZER_IMAGES` list. Keep
`SAST_DEFAULT_ANALYZERS` set to an empty string `""`.

#### Workaround 2: Disable Docker-in-Docker for SAST and Dependency Scanning (GitLab 12.3 and later)

Disable Docker-in-Docker for SAST. Individual `<analyzer-name>-sast` jobs are created for each
analyzer that runs in your CI/CD pipeline.

```yaml
include:
  - template: SAST.gitlab-ci.yml

variables:
  SAST_DISABLE_DIND: "true"
```

#### Workaround 3: Upgrade to GitLab 13.x and use the defaults

From GitLab 13.0, SAST defaults to not using Docker-in-Docker. In GitLab 13.4 and later, SAST using
Docker-in-Docker is [no longer supported](https://gitlab.com/gitlab-org/gitlab/-/issues/220540).
If you have this problem on GitLab 13.x and later, you have customized your SAST job to
use Docker-in-Docker. To resolve this, comment out any customizations you've made to
your SAST CI job definition and [follow the documentation](index.md#configuration)
to reconfigure, using the new and improved job definition default values.

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
```
