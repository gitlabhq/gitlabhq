---
type: reference, howto
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Secret Detection

> - [Introduced](https://about.gitlab.com/releases/2019/03/22/gitlab-11-9-released/#detect-secrets-and-credentials-in-the-repository) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.9.
> - Made [available in all tiers](https://gitlab.com/gitlab-org/gitlab/-/issues/222788) in 13.3.

A recurring problem when developing applications is that developers may unintentionally commit
secrets and credentials to their remote repositories. If other people have access to the source,
or if the project is public, the sensitive information is then exposed and can be leveraged by
malicious users to gain access to resources like deployment environments.

GitLab 11.9 includes a new check called Secret Detection. It scans the content of the repository
to find API keys and other information that should not be there.

GitLab displays identified secrets visibly in a few places:

- [Security Dashboard](../security_dashboard/)
- Pipelines' **Security** tab
- Report in the merge request widget

![Secret Detection in merge request widget](img/secret_detection_v13_2.png)

## Use cases

- Detecting unintentional commit of secrets like keys, passwords, and API tokens.
- Performing a single or recurring scan of the full history of your repository for secrets.

## Supported secrets

Secret Detection detects a variety of common secrets by default. You can also customize the secret detection patterns using [custom rulesets](#custom-rulesets).

The [default ruleset provided by Gitleaks](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/gitleaks/gitleaks.toml) includes the following key types:

- Cloud services:
  - Amazon Web Services (AWS)
  - Google Cloud Platform (GCP)
Encryption keys:
  - PKCS8
  - RSA
  - SSH
  - PGP
- Social media platforms:
  - Facebook API
  - Twitter API
- Cloud SaaS vendors:
  - GitHub API
  - Slack Token
  - Stripe API
  - Generic API key strings starting with `api-`

## Requirements

To run Secret Detection jobs, by default, you need GitLab Runner with the
[`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
If you're using the shared runners on GitLab.com, this is enabled by default.

CAUTION: **Caution:**
Our Secret Detection jobs expect a Linux container type. Windows containers are not supported.

CAUTION: **Caution:**
If you use your own runners, make sure the Docker version installed
is **not** `19.03.0`. See [troubleshooting information](../sast#error-response-from-daemon-error-processing-tar-file-docker-tar-relocation-error) for details.

### Making Secret Detection available to all GitLab tiers

To make Secret Detection available to as many customers as possible, we have enabled it for all GitLab tiers.
However not all features are available on every tier. See the breakdown below for more details.

#### Summary of features per tier

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/),
as shown in the following table:

| Capability                                                                | In Core             | In Ultimate        |
|:--------------------------------------------------------------------------|:--------------------|:-------------------|
| [Configure Secret Detection Scanners](#configuration)                                 | **{check-circle}**  | **{check-circle}** |
| [Customize Secret Detection Settings](#customizing-settings)                 | **{check-circle}**  | **{check-circle}** |
| View [JSON Report](../sast/index.md#reports-json-format)                                  | **{check-circle}**  | **{check-circle}** |
| Presentation of JSON Report in Merge Request                 | **{dotted-circle}** | **{check-circle}** |
| [Interaction with Vulnerabilities](../vulnerabilities/index.md) | **{dotted-circle}** | **{check-circle}** |
| [Access to Security Dashboard](../security_dashboard/index.md)                       | **{dotted-circle}** | **{check-circle}** |

## Configuration

> GitLab 13.1 splits Secret Detection from the [SAST configuration](../sast#configuration) into its own CI/CD template. If you're using GitLab 13.0 or earlier and SAST is enabled, then Secret Detection is already enabled.

Secret Detection is performed by a [specific analyzer](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Secret-Detection.gitlab-ci.yml)
during the `secret-detection` job. It runs regardless of your app's programming language.

The Secret Detection analyzer includes [Gitleaks](https://github.com/zricethezav/gitleaks) and
[TruffleHog](https://github.com/dxa4481/truffleHog) checks.

Note that the Secret Detection analyzer ignores Password-in-URL vulnerabilities if the password
begins with a dollar sign (`$`), as this likely indicates the password is an environment variable.
For example, `https://username:$password@example.com/path/to/repo` isn't detected, while
`https://username:password@example.com/path/to/repo` is.

NOTE: **Note:**
You don't have to configure Secret Detection manually as shown in this section if you're using
[Auto Secret Detection](../../../topics/autodevops/stages.md#auto-secret-detection)
provided by [Auto DevOps](../../../topics/autodevops/index.md).

To enable Secret Detection for GitLab 13.1 and later, you must include the
`Secret-Detection.gitlab-ci.yml` template that's provided as a part of your GitLab installation. For
GitLab versions earlier than 11.9, you can copy and use the job as defined in that template.

Add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Security/Secret-Detection.gitlab-ci.yml
```

The included template creates Secret Detection jobs in your CI/CD pipeline and scans
your project's source code for secrets.

The results are saved as a
[Secret Detection report artifact](../../../ci/pipelines/job_artifacts.md#artifactsreportssecret_detection)
that you can later download and analyze. Due to implementation limitations, we
always take the latest Secret Detection artifact available.

### Post-processing

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4639) in GitLab 13.6.

Upon detection of a secret, GitLab supports post processing hooks. These can be used to take actions like notifying the cloud service who issued the secret. The cloud provider can confirm the credentials and take remediation actions like revoking or reissuing a new secret and notifying the creator of the secret. Post-processing workflows vary by supported cloud providers. 

GitLab currently supports post-processing for following service providers:

- Amazon Web Services (AWS)

Third party cloud and SaaS providers can [express integration interest by filling out this form](https://forms.gle/wWpvrtLRK21Q2WJL9). Learn more about the [technical details of post-processing secrets](https://gitlab.com/groups/gitlab-org/-/epics/4639). 

### Customizing settings

The Secret Detection scan settings can be changed through [environment variables](#available-variables)
by using the
[`variables`](../../../ci/yaml/README.md#variables) parameter in `.gitlab-ci.yml`.

To override a job definition, (for example, change properties like `variables` or `dependencies`),
declare a job with the same name as the SAST job to override. Place this new job after the template
inclusion and specify any additional keys under it.

In the following example, we include the Secret Detection template and at the same time we
override the `secret_detection` job with the `SECRET_DETECTION_HISTORIC_SCAN` variable to `true`:

```yaml
include:
  - template: Security/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_HISTORIC_SCAN: "true"
```

Because the template is [evaluated before](../../../ci/yaml/README.md#include)
the pipeline configuration, the last mention of the variable takes precedence.

CAUTION: **Deprecation:**
Beginning in GitLab 13.0, the use of [`only` and `except`](../../../ci/yaml/README.md#onlyexcept-basic)
is no longer supported. When overriding the template, you must use [`rules`](../../../ci/yaml/README.md#rules) instead.

#### Available variables

Secret Detection can be customized by defining available variables:

| Environment variable    | Default value | Description |
|-------------------------|---------------|-------------|
| `SECRET_DETECTION_COMMIT_FROM` | -     | The commit a Gitleaks scan starts at. |
| `SECRET_DETECTION_COMMIT_TO` | -       | The commit a Gitleaks scan ends at. |
| `SECRET_DETECTION_EXCLUDED_PATHS` | "" | Exclude vulnerabilities from output based on the paths. This is a comma-separated list of patterns. Patterns can be globs, or file or folder paths (for example, `doc,spec` ). Parent directories also match patterns. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225273) in GitLab 13.3. |
| `SECRET_DETECTION_HISTORIC_SCAN` | false | Flag to enable a historic Gitleaks scan. |

### Custom rulesets **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/211387) in GitLab 13.5.

You can customize the default secret detection rules provided with GitLab.
Customization allows you to exclude rules and add new rules.

To create a custom ruleset:

1. Create a `.gitlab` directory at the root of your project, if one doesn't already exist.
1. Create a custom ruleset file named `secret-detection-ruleset.toml` in the `.gitlab` directory.
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

### Logging level

To control the verbosity of logs set the `SECURE_LOG_LEVEL` environment variable. Messages of this logging level or higher are output. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10880) in GitLab 13.1.

From highest to lowest severity, the logging levels are:

- `fatal`
- `error`
- `warn`
- `info` (default)
- `debug`

## Full History Secret Scan

GitLab 12.11 introduced support for scanning the full history of a repository. This new functionality
is particularly useful when you are enabling Secret Detection in a repository for the first time and you
want to perform a full secret scan. Running a secret scan on the full history can take a long time,
especially for larger repositories with lengthy Git histories. We recommend not setting this variable
as part of your normal job definition.

A new configuration variable ([`SECRET_DETECTION_HISTORIC_SCAN`](../sast/#vulnerability-filters))
can be set to change the behavior of the GitLab Secret Detection scan to run on the entire Git history of a repository.

We have created a [short video walkthrough](https://youtu.be/wDtc_K00Y0A) showcasing how you can perform a full history secret scan.
<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=wDtc_K00Y0A">Walkthrough of historical secret scan</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/wDtc_K00Y0A" frameborder="0" allowfullscreen="true"> </iframe>
</figure>

### Make GitLab Secret Detection analyzer image available inside your Docker registry

Import the following default Secret Detection analyzer images from `registry.gitlab.com` into your
[local Docker container registry](../../packages/container_registry/index.md):

```plaintext
registry.gitlab.com/gitlab-org/security-products/analyzers/secrets:3
```

The process for importing Docker images into a local offline Docker registry depends on
**your network security policy**. Please consult your IT staff to find an accepted and approved
process by which external resources can be imported or temporarily accessed. Note that these scanners are [updated periodically](../index.md#maintenance-and-update-of-the-vulnerabilities-database)
with new definitions, so consider if you're able to make periodic updates yourself.

For details on saving and transporting Docker images as a file, see Docker's documentation on
[`docker save`](https://docs.docker.com/engine/reference/commandline/save/), [`docker load`](https://docs.docker.com/engine/reference/commandline/load/),
[`docker export`](https://docs.docker.com/engine/reference/commandline/export/), and [`docker import`](https://docs.docker.com/engine/reference/commandline/import/).

#### If support for Custom Certificate Authorities are needed

Support for custom certificate authorities was introduced in the following versions.

| Analyzer | Version |
| -------- | ------- |
| secrets | [v3.0.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v3.0.0) |

## Troubleshooting

### Getting warning message `gl-secret-detection-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../ci/pipelines/job_artifacts.md#error-message-no-files-to-upload).

### Error: `Couldn't run the gitleaks command: exit status 2`

This error is usually caused by the `GIT_DEPTH` value of 50 that is set for all [projects by default](../../../ci/pipelines/settings.md#git-shallow-clone). 

For example, if a pipeline is triggered from a Merge Request containing 60 commits while the `GIT_DEPTH` is set to 50, the Secret Detection job will fail as the clone will not have been deep enough to contain all of the relevant commits. 

You can confirm this to be the cause of the error by implementing a [logging level](../../application_security/secret_detection/index.md#logging-level) of `debug`. Once implemented, the logs should look similar to the following example, wherein an "object not found" error can be seen:

```plaintext
ERRO[2020-11-18T18:05:52Z] object not found                             
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Couldn't run the gitleaks command: exit status 2
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Gitleaks analysis failed: exit status 2
```

If this is the case, we can resolve the issue by setting the [`GIT_DEPTH` variable](../../../ci/runners/README.md#shallow-cloning) to a higher value. In order to apply this only to the Secret Detection job, the following can be added to your `.gitlab-ci.yml`:

```yaml
secret_detection:
  variables:
    GIT_DEPTH: 100
```
