---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Secret Detection **(FREE)**

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/222788) from GitLab Ultimate to GitLab Free in 13.3.

A recurring problem when developing applications is that people may accidentally commit secrets to
their remote Git repositories. Secrets include keys, passwords, API tokens, and other sensitive
information. Anyone with access to the repository could use the secrets for malicious purposes.
Secrets exposed in this way must be treated as compromised, and be replaced, which can be costly.
It's important to prevent secrets from being committed to a Git repository.

Secret Detection uses the [Gitleaks](https://github.com/zricethezav/gitleaks) tool to scan the
repository for secrets. All identified secrets are reported in the:

- Merge request widget
- Pipelines' **Security** tab
- [Security Dashboard](../security_dashboard/)

![Secret Detection in merge request widget](img/secret_detection_v13_2.png)

WARNING:
Secret Detection does not support scanning binary files.

## Detected secrets

Secret Detection uses a [default ruleset](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/gitleaks.toml)
containing more than 90 secret detection patterns. You can also customize the secret detection
patterns using [custom rulesets](#custom-rulesets). If you want to contribute rulesets for
"well-identifiable" secrets, follow the steps detailed in the
[community contributions guidelines](https://gitlab.com/gitlab-org/gitlab/-/issues/345453).

## Requirements

To run Secret Detection jobs, by default, you need GitLab Runner with the
[`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
If you're using the shared runners on GitLab.com, this is enabled by default.

WARNING:
Our Secret Detection jobs expect a Linux/amd64 container type. Windows containers are not supported.

WARNING:
If you use your own runners, make sure the Docker version installed
is **not** `19.03.0`. See [troubleshooting information](../sast#error-response-from-daemon-error-processing-tar-file-docker-tar-relocation-error) for details.

### Making Secret Detection available to all GitLab tiers

To make Secret Detection available to as many customers as possible, we have enabled it for all GitLab tiers.
However not all features are available on every tier. See the breakdown below for more details.

#### Summary of features per tier

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/),
as shown in the following table:

| Capability                                                      | In Free & Premium   | In Ultimate        |
|:----------------------------------------------------------------|:--------------------|:-------------------|
| [Configure Secret Detection scanner](#configuration)            | **{check-circle}**  | **{check-circle}** |
| [Customize Secret Detection settings](#customizing-settings)    | **{check-circle}**  | **{check-circle}** |
| Download [JSON Report](../sast/index.md#reports-json-format)    | **{check-circle}**  | **{check-circle}** |
| See new findings in the merge request widget                    | **{dotted-circle}** | **{check-circle}** |
| View identified secrets in the pipelines' **Security** tab      | **{dotted-circle}** | **{check-circle}** |
| [Manage vulnerabilities](../vulnerabilities/index.md)           | **{dotted-circle}** | **{check-circle}** |
| [Access the Security Dashboard](../security_dashboard/index.md) | **{dotted-circle}** | **{check-circle}** |
| [Customize Secret Detection rulesets](#custom-rulesets)         | **{dotted-circle}** | **{check-circle}** |

## Configuration

> - In GitLab 13.1, Secret Detection was split from the [SAST configuration](../sast#configuration) into its own CI/CD template. If you're using GitLab 13.0 or earlier and SAST is enabled, then Secret Detection is already enabled.
> - [In GitLab 14.0](https://gitlab.com/gitlab-org/gitlab/-/issues/297269), Secret Detection jobs `secret_detection_default_branch` and `secret_detection` were consolidated into one job, `secret_detection`.

Secret Detection is performed by a [specific analyzer](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Secret-Detection.gitlab-ci.yml)
during the `secret-detection` job. It runs regardless of your app's programming language.

The Secret Detection analyzer includes [Gitleaks](https://github.com/zricethezav/gitleaks) checks.

Note that the Secret Detection analyzer ignores Password-in-URL vulnerabilities if the password
begins with a dollar sign (`$`), as this likely indicates the password is an environment variable.
For example, `https://username:$password@example.com/path/to/repo` isn't detected, while
`https://username:password@example.com/path/to/repo` is.

NOTE:
You don't have to configure Secret Detection manually as shown in this section if you're using
[Auto Secret Detection](../../../topics/autodevops/stages.md#auto-secret-detection),
provided by [Auto DevOps](../../../topics/autodevops/index.md).

To enable Secret Detection for GitLab 13.1 and later, you must include the
`Secret-Detection.gitlab-ci.yml` template that's provided as a part of your GitLab installation. For
GitLab versions earlier than 11.9, you can copy and use the job as defined in that template.

Ensure your `.gitlab-ci.yml` file has a `stage` called `test`, and add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Security/Secret-Detection.gitlab-ci.yml
```

The included template creates Secret Detection jobs in your CI/CD pipeline and scans
your project's source code for secrets.

The results are saved as a
[Secret Detection report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportssecret_detection)
that you can later download and analyze. Due to implementation limitations, we
always take the latest Secret Detection artifact available.

### Supported distributions

The default scanner images are build off a base Alpine image for size and maintainability.

#### FIPS-enabled images

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6479) in GitLab 14.10.

GitLab offers [Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)
versions of the images that are FIPS-enabled. To use the FIPS-enabled images, you can either:

- Set the `SAST_IMAGE_SUFFIX` to `-fips`.
- Add the `-fips` extension to the default image name.

For example:

```yaml
variables:
  SECRET_DETECTION_IMAGE_SUFFIX: '-fips'

include:
  - template: Security/Secret-Detection.gitlab-ci.yml
```

### Enable Secret Detection via an automatic merge request

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4496) in GitLab 13.11, deployed behind a feature flag, enabled by default.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/329886) in GitLab 14.1.

NOTE:
This method works best with no existing `.gitlab-ci.yml` file, or with a minimal configuration
file. If you have a complex GitLab configuration file it may not be parsed successfully, and an
error may occur.

To enable Secret Detection in a project, you can create a merge request:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Configuration**.
1. In the **Secret Detection** row, select **Configure with a merge request**.
1. Review and merge the merge request to enable Secret Detection.

Pipelines now include a Secret Detection job.

### Customizing settings

The Secret Detection scan settings can be changed through [CI/CD variables](#available-cicd-variables)
by using the
[`variables`](../../../ci/yaml/index.md#variables) parameter in `.gitlab-ci.yml`.

WARNING:
All customization of GitLab security scanning tools should be tested in a merge request before
merging these changes to the default branch. Failure to do so can give unexpected results,
including a large number of false positives.

To override a job definition, (for example, change properties like `variables` or `dependencies`),
declare a job with the same name as the secret detection job to override. Place this new job after the template
inclusion and specify any additional keys under it.

WARNING:
Beginning in GitLab 13.0, the use of [`only` and `except`](../../../ci/yaml/index.md#only--except)
is no longer supported. When overriding the template, you must use [`rules`](../../../ci/yaml/index.md#rules) instead.

#### `GIT_DEPTH` variable

The [`GIT_DEPTH` CI/CD variable](../../../ci/runners/configure_runners.md#shallow-cloning) affects Secret Detection.
The Secret Detection analyzer relies on generating patches between commits to scan content for
secrets. If you override the default, ensure the value is greater than 1. If the number of commits
in an MR is greater than the `GIT_DEPTH` value, Secret Detection will [fail to detect secrets](#error-couldnt-run-the-gitleaks-command-exit-status-2).

#### Custom settings example

In the following example, we include the Secret Detection template and at the same time we
override the `secret_detection` job with the `SECRET_DETECTION_HISTORIC_SCAN` CI/CD variable to `true`:

```yaml
include:
  - template: Security/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_HISTORIC_SCAN: "true"
```

Because the template is [evaluated before](../../../ci/yaml/index.md#include)
the pipeline configuration, the last mention of the variable takes precedence.

#### Available CI/CD variables

Secret Detection can be customized by defining available CI/CD variables:

| CI/CD variable                    | Default value | Description |
|-----------------------------------|---------------|-------------|
| `SECRET_DETECTION_EXCLUDED_PATHS` | ""            | Exclude vulnerabilities from output based on the paths. This is a comma-separated list of patterns. Patterns can be globs (see [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) for supported patterns), or file or folder paths (for example, `doc,spec` ). Parent directories also match patterns. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225273) in GitLab 13.3. |
| `SECRET_DETECTION_HISTORIC_SCAN`  | false         | Flag to enable a historic Gitleaks scan. |
| `SECRET_DETECTION_IMAGE_SUFFIX`   | "" | Suffix added to the image name. If set to `-fips`, `FIPS-enabled` images are used for scan. See [FIPS-enabled images](#fips-enabled-images) for more details. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355519) in GitLab 14.10. |
| `SECRET_DETECTION_LOG_OPTIONS`  | ""         | [`git log`](https://git-scm.com/docs/git-log) options used to define commit ranges. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350660) in GitLab 15.1.|

In previous GitLab versions, the following variables were also available:

| CI/CD variable                    | Default value | Description |
|-----------------------------------|---------------|-------------|
| `SECRET_DETECTION_COMMIT_FROM`    | -             | The commit a Gitleaks scan starts at. [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) in GitLab 13.5. Replaced with `SECRET_DETECTION_COMMITS`. |
| `SECRET_DETECTION_COMMIT_TO`      | -             | The commit a Gitleaks scan ends at. [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) in GitLab 13.5. Replaced with `SECRET_DETECTION_COMMITS`. |
| `SECRET_DETECTION_COMMITS`        | -             | The list of commits that Gitleaks should scan. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) in GitLab 13.5.  [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/352565) in GitLab 15.0. |

### Custom rulesets **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/211387) in GitLab 13.5.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/339614) support for
>   passthrough chains. Expanded to include additional passthrough types of `file`, `git`, and `url` in GitLab 14.6.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/235359) support for overriding rules in GitLab 14.8.

You can customize the default secret detection rules provided with GitLab.
Ruleset customization supports the following capabilities that can be used
simultaneously:

- [Disabling predefined rules](#disable-predefined-analyzer-rules).
- [Overriding predefined rules](#override-predefined-analyzer-rules).
- Modifying the default behavior of the Secret Detection analyzer by [synthesizing and passing a custom configuration](#synthesize-a-custom-configuration).

Customization allows replacing the default secret detection rules with rules that you define.

To create a custom ruleset:

1. Create a `.gitlab` directory at the root of your project, if one doesn't already exist.
1. Create a custom ruleset file named `secret-detection-ruleset.toml` in the `.gitlab` directory.

#### Disable predefined analyzer rules

To disable analyzer rules:

1. Set the `disabled` flag to `true` in the context of a `ruleset` section.

1. In one or more `ruleset.identifier` subsections, list the rules that you want disabled. Every `ruleset.identifier` section has:

   - a `type` field, to name the predefined rule identifier.
   - a `value` field, to name the rule to be disabled.

##### Example: Disable predefined rules of Secret Detection analyzer

In the following example, the disabled rules is assigned to `secrets`
by matching the `type` and `value` of identifiers:

```toml
[secrets]
  [[secrets.ruleset]]
    disable = true
    [secrets.ruleset.identifier]
      type = "gitleaks_rule_id"
      value = "RSA private key"
```

#### Override predefined analyzer rules

To override rules:

1. In one or more `ruleset.identifier` subsections, list the rules that you want to override. Every `ruleset.identifier` section has:

   - a `type` field, to name the predefined rule identifier that the Secret Detection analyzer uses.
   - a `value` field, to name the rule to be overridden.

1. In the `ruleset.override` context of a `ruleset` section,
   provide the keys to override. Any combination of keys can be
   overridden. Valid keys are:

   - description
   - message
   - name
   - severity (valid options are: Critical, High, Medium, Low, Unknown, Info)

##### Example: Override predefined rules of Secret Detection analyzer

In the following example, rules
are matched by the `type` and `value` of identifiers and
then overridden:

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.identifier]
      type = "gitleaks_rule_id"
      value = "RSA private key"
    [secrets.ruleset.override]
      description = "OVERRIDDEN description"
      message = "OVERRIDDEN message"
      name = "OVERRIDDEN name"
      severity = "Info"
```

#### Synthesize a custom configuration

To create a custom configuration, you can use passthrough chains.

1. In the `secret-detection-ruleset.toml` file, do one of the following:

   - Define a custom ruleset:

     ```toml
     [secrets]
       description = 'secrets custom rules configuration'

       [[secrets.passthrough]]
         type  = "raw"
         target = "gitleaks.toml"
         value = """\
     title = "gitleaks config"
     # add regexes to the regex table
     [[rules]]
     description = "Test for Raw Custom Rulesets"
     regex = '''Custom Raw Ruleset T[est]{3}'''
     """
     ```

   - Provide the name of the file containing a custom ruleset:

     ```toml
     [secrets]
       description = 'secrets custom rules configuration'

       [[secrets.passthrough]]
         type  = "file"
         target = "gitleaks.toml"
         value = "config/gitleaks.toml"
     ```

Passthroughs can also be chained to build more complex configurations.
For more details, see [SAST Customize ruleset section](../sast/customize_rulesets.md).

### Logging level

To control the verbosity of logs set the `SECURE_LOG_LEVEL` CI/CD variable. Messages of this logging level or higher are output. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10880) in GitLab 13.1.

From highest to lowest severity, the logging levels are:

- `fatal`
- `error`
- `warn`
- `info` (default)
- `debug`

## Post-processing and revocation

Upon detection of a secret, GitLab SaaS supports post-processing hooks.
For more information, see [Post-processing and revocation](post_processing.md).

## Full History Secret Detection

GitLab 12.11 introduced support for scanning the full history of a repository. This new functionality
is particularly useful when you are enabling Secret Detection in a repository for the first time and you
want to perform a full secret detection scan. Running a secret detection scan on the full history can take a long time,
especially for larger repositories with lengthy Git histories. We recommend not setting this CI/CD variable
as part of your normal job definition.

A new configuration variable ([`SECRET_DETECTION_HISTORIC_SCAN`](#available-cicd-variables))
can be set to change the behavior of the GitLab Secret Detection scan to run on the entire Git history of a repository.

## Running Secret Detection in an offline environment

For self-managed GitLab instances in an environment with limited, restricted, or intermittent access
to external resources through the internet, some adjustments are required for the Secret Detection job to
run successfully. For more information, see [Offline environments](../offline_deployments/index.md).

### Requirements for offline Secret Detection

To use Secret Detection in an offline environment, you need:

- GitLab Runner with the [`docker` or `kubernetes` executor](#requirements).
- A Docker Container Registry with locally available copy of Secret Detection [analyzer](https://gitlab.com/gitlab-org/security-products/analyzers) images.
- Configure certificate checking of packages (optional).

GitLab Runner has a [default `pull policy` of `always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy),
meaning the runner tries to pull Docker images from the GitLab container registry even if a local
copy is available. The GitLab Runner [`pull_policy` can be set to `if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)
in an offline environment if you prefer using only locally available Docker images. However, we
recommend keeping the pull policy setting to `always` if not in an offline environment, as this
enables the use of updated scanners in your CI/CD pipelines.

### Make GitLab Secret Detection analyzer image available inside your Docker registry

Import the following default Secret Detection analyzer images from `registry.gitlab.com` into your
[local Docker container registry](../../packages/container_registry/index.md):

```plaintext
registry.gitlab.com/security-products/secret-detection:3
```

The process for importing Docker images into a local offline Docker registry depends on
**your network security policy**. Please consult your IT staff to find an accepted and approved
process by which external resources can be imported or temporarily accessed. These scanners are [periodically updated](../index.md#vulnerability-scanner-maintenance)
with new definitions, and you may be able to make occasional updates on your own.

For details on saving and transporting Docker images as a file, see Docker's documentation on
[`docker save`](https://docs.docker.com/engine/reference/commandline/save/), [`docker load`](https://docs.docker.com/engine/reference/commandline/load/),
[`docker export`](https://docs.docker.com/engine/reference/commandline/export/), and [`docker import`](https://docs.docker.com/engine/reference/commandline/import/).

### Set Secret Detection CI/CD variables to use the local Secret Detection analyzer container image

Add the following configuration to your `.gitlab-ci.yml` file. You must replace
`SECURE_ANALYZERS_PREFIX` to refer to your local Docker container registry:

```yaml
include:
  - template: Security/Secret-Detection.gitlab-ci.yml

variables:
  SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
```

The Secret Detection job should now use the local copy of the Secret Detection analyzer Docker image to scan your code and generate
security reports without requiring internet access.

#### If support for Custom Certificate Authorities are needed

Support for custom certificate authorities was introduced in the following versions.

| Analyzer | Version |
| -------- | ------- |
| secrets | [v3.0.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v3.0.0) |

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

## Troubleshooting

### Getting warning message `gl-secret-detection-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../ci/pipelines/job_artifacts.md#error-message-no-files-to-upload).

### Error: `Couldn't run the gitleaks command: exit status 2`

If a pipeline is triggered from a merge request containing 60 commits while the `GIT_DEPTH` variable's
value is less than that, the Secret Detection job fails as the clone is not deep enough to contain all of the
relevant commits. For information on the current default value, see the
[pipeline configuration documentation](../../../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone).

To confirm this as the cause of the error, set the
[logging level](../../application_security/secret_detection/index.md#logging-level) to `debug`, then
rerun the pipeline. The logs should look similar to the following example. The text "object not
found" is a symptom of this error.

```plaintext
ERRO[2020-11-18T18:05:52Z] object not found
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Couldn't run the gitleaks command: exit status 2
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Gitleaks analysis failed: exit status 2
```

To resolve the issue, set the [`GIT_DEPTH` CI/CD variable](../../../ci/runners/configure_runners.md#shallow-cloning)
to a higher value. To apply this only to the Secret Detection job, the following can be added to
your `.gitlab-ci.yml` file:

```yaml
secret_detection:
  variables:
    GIT_DEPTH: 100
```

### `secret-detection` job fails with `ERR fatal: ambiguous argument` message

Your `secret-detection` job can fail with `ERR fatal: ambiguous argument` error if your
repository's default branch is unrelated to the branch the job was triggered for.
See issue [!352014](https://gitlab.com/gitlab-org/gitlab/-/issues/352014) for more details.

To resolve the issue, make sure to correctly [set your default branch](../../project/repository/branches/default.md#change-the-default-branch-name-for-a-project) on your repository. You should set it to a branch
that has related history with the branch you run the `secret-detection` job on.
