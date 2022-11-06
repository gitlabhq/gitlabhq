---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Secret Detection **(FREE)**

> - In GitLab 13.1, Secret Detection was split from the [SAST configuration](../sast/index.md#configuration)
>   into its own CI/CD template. If you're using GitLab 13.0 or earlier and SAST is enabled, then
>   Secret Detection is already enabled.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/222788) from GitLab Ultimate to GitLab
>   Free in 13.3.
> - [In GitLab 14.0](https://gitlab.com/gitlab-org/gitlab/-/issues/297269), Secret Detection jobs
>   `secret_detection_default_branch` and `secret_detection` were consolidated into one job,
>   `secret_detection`.

People may accidentally commit secrets (such as keys, passwords, and API tokens) to remote Git repositories.

Anyone with access to the repository could use the secrets for malicious purposes. Exposed secrets
must be considered compromised and be replaced, which can be costly.

To help prevent secrets from being committed to a Git repository, you can use Secret Detection to
scan your repository for secrets. Scanning is language and framework agnostic, but does not support
scanning binary files.

Secret Detection uses an analyzer containing the [Gitleaks](https://github.com/zricethezav/gitleaks)
tool to scan the repository for secrets. Detection occurs in the `secret-detection` job. The results
are saved as a
[Secret Detection report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportssecret_detection)
that you can later download and analyze. Due to implementation limitations, we always take the
latest Secret Detection artifact available.

GitLab SaaS supports post-processing hooks, so you can take action when a secret is found. For
more information, see [Post-processing and revocation](post_processing.md).

All identified secrets are reported in the:

- Merge request widget
- Pipelines' **Security** tab
- [Vulnerability Report](../vulnerability_report/index.md)

![Secret Detection in merge request widget](img/secret_detection_v13_2.png)

## Detected secrets

Secret Detection uses a [default ruleset](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/gitleaks.toml)
containing more than 90 secret detection patterns. You can also customize the secret detection
patterns using [custom rulesets](#custom-rulesets). If you want to contribute rulesets for
"well-identifiable" secrets, follow the steps detailed in the
[community contributions guidelines](https://gitlab.com/gitlab-org/gitlab/-/issues/345453).

## Features per tier

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/).

| Capability                                                       | In Free & Premium      | In Ultimate            |
|:---------------------------------------------------------------- |:-----------------------|:-----------------------|
| [Configure Secret Detection scanner](#enable-secret-detection)   | **{check-circle}** Yes | **{check-circle}** Yes |
| [Customize Secret Detection settings](#configure-scan-settings)  | **{check-circle}** Yes | **{check-circle}** Yes |
| Download [JSON Report](../sast/index.md#reports-json-format)     | **{check-circle}** Yes | **{check-circle}** Yes |
| See new findings in the merge request widget                     | **{dotted-circle}** No | **{check-circle}** Yes |
| View identified secrets in the pipelines' **Security** tab       | **{dotted-circle}** No | **{check-circle}** Yes |
| [Manage vulnerabilities](../vulnerability_report/index.md)       | **{dotted-circle}** No | **{check-circle}** Yes |
| [Access the Security Dashboard](../security_dashboard/index.md)  | **{dotted-circle}** No | **{check-circle}** Yes |
| [Customize Secret Detection rulesets](#custom-rulesets)          | **{dotted-circle}** No | **{check-circle}** Yes |

## Enable Secret Detection

Prerequisites:

- GitLab Runner with the [`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor. If you're using the
shared runners on GitLab.com, this is enabled by default.
- If you use your own runners, make sure the Docker version installed is **not** `19.03.0`. See
  [troubleshooting information](../sast#error-response-from-daemon-error-processing-tar-file-docker-tar-relocation-error)
  for details.
- Linux/amd64 container type. Windows containers are not supported.
- GitLab CI/CD configuration (`.gitlab-ci.yml`) must include the `test` stage.

To enable Secret Detection, either:

- Enable [Auto DevOps](../../../topics/autodevops/index.md), which includes [Auto Secret Detection](../../../topics/autodevops/stages.md#auto-secret-detection).

- [Enable Secret Detection by including the template](#enable-secret-detection-by-including-the-template).

- [Enable Secret Detection using a merge request](#enable-secret-detection-using-a-merge-request).

### Enable Secret Detection by including the template

You should use this method if you have an existing GitLab CI/CD configuration file.

Add the following extract to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml
```

Pipelines now include a Secret Detection job, and the results are included in the merge request
widget.

### Enable Secret Detection using a merge request

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4496) in GitLab 13.11, deployed behind a feature flag, enabled by default.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/329886) in GitLab 14.1.

NOTE:
This method works best with no existing `.gitlab-ci.yml` file, or with a minimal configuration
file. If you have a complex GitLab configuration file it may not be parsed successfully, and an
error may occur.

To enable Secret Detection using a merge request:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Configuration**.
1. In the **Secret Detection** row, select **Configure with a merge request**.
1. Review and merge the merge request.

Pipelines now include a Secret Detection job, and the results are included in the merge request
widget.

## Responding to a leaked secret

If the scanner detects a secret you should rotate it immediately. [Purging a file from the repository's history](../../project/repository/reducing_the_repo_size_using_git.md#purge-files-from-repository-history) may not be effective in removing all references to the file. Also, the secret remains in any forks of the repository.

## Configure scan settings

The Secret Detection scan settings can be changed through [CI/CD variables](#available-cicd-variables)
by using the [`variables`](../../../ci/yaml/index.md#variables) parameter in `.gitlab-ci.yml`.

WARNING:
All configuration of GitLab security scanning tools should be tested in a merge request before
merging these changes to the default branch. Failure to do so can give unexpected results,
including a large number of false positives.

To override a job definition, (for example, change properties like `variables` or `dependencies`),
declare a job with the same name as the secret detection job to override. Place this new job after
the template inclusion and specify any additional keys under it.

In the following example _extract_ of a `.gitlab-ci.yml` file:

- The Secret Detection template is [included](../../../ci/yaml/index.md#include).
- In the `secret_detection` job, the CI/CD variable `SECRET_DETECTION_HISTORIC_SCAN` is set to
  `true`. Because the template is evaluated before the pipeline configuration, the last mention of
  the variable takes precedence.

```yaml
include:
  - template: Security/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_HISTORIC_SCAN: "true"
```

### Ignore secrets

In some instances, you might want to ignore a secret. For example, you may have a fake secret in an
example or a test suite. In these instances, you want to ignore the secret, instead of having it
reported as a vulnerability.

To ignore a secret, add `gitleaks:allow` as a comment to the line that contains the secret.

For example:

```ruby
 "A personal token for GitLab will look like glpat-JUST20LETTERSANDNUMB" #gitleaks:allow
```

### Available CI/CD variables

Secret Detection can be customized by defining available CI/CD variables:

| CI/CD variable                    | Default value | Description |
|-----------------------------------|---------------|-------------|
| `SECRET_DETECTION_EXCLUDED_PATHS` | ""            | Exclude vulnerabilities from output based on the paths. The paths are a comma-separated list of patterns. Patterns can be globs (see [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) for supported patterns), or file or folder paths (for example, `doc,spec` ). Parent directories also match patterns. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225273) in GitLab 13.3. |
| `SECRET_DETECTION_HISTORIC_SCAN`  | false         | Flag to enable a historic Gitleaks scan. |
| `SECRET_DETECTION_IMAGE_SUFFIX`   | "" | Suffix added to the image name. If set to `-fips`, `FIPS-enabled` images are used for scan. See [Use FIPS-enabled images](#use-fips-enabled-images) for more details. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355519) in GitLab 14.10. |
| `SECRET_DETECTION_LOG_OPTIONS`  | ""         | [`git log`](https://git-scm.com/docs/git-log) options used to define commit ranges. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350660) in GitLab 15.1.|

In previous GitLab versions, the following variables were also available:

| CI/CD variable                    | Default value | Description |
|-----------------------------------|---------------|-------------|
| `SECRET_DETECTION_COMMIT_FROM`    | -             | The commit a Gitleaks scan starts at. [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) in GitLab 13.5. Replaced with `SECRET_DETECTION_COMMITS`. |
| `SECRET_DETECTION_COMMIT_TO`      | -             | The commit a Gitleaks scan ends at. [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) in GitLab 13.5. Replaced with `SECRET_DETECTION_COMMITS`. |
| `SECRET_DETECTION_COMMITS`        | -             | The list of commits that Gitleaks should scan. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) in GitLab 13.5. [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/352565) in GitLab 15.0. |

#### Use FIPS-enabled images

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6479) in GitLab 14.10.

The default scanner images are built off a base Alpine image for size and maintainability. GitLab
offers [Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)
versions of the images that are FIPS-enabled.

To use the FIPS-enabled images, either:

- Set the `SECRET_DETECTION_IMAGE_SUFFIX` CI/CD variable to `-fips`.
- Add the `-fips` extension to the default image name.

For example:

```yaml
variables:
  SECRET_DETECTION_IMAGE_SUFFIX: '-fips'

include:
  - template: Security/Secret-Detection.gitlab-ci.yml
```

## Full history Secret Detection

By default, Secret Detection scans only the current state of the Git repository. Any secrets
contained in the repository's history are not detected. To address this, Secret Detection can
scan the Git repository's full history.

You should do a full history scan only once, after enabling Secret Detection. A full history
can take a long time, especially for larger repositories with lengthy Git histories. After
completing an initial full history scan, use only standard Secret Detection as part of your
pipeline.

### Enable full history Secret Detection

To enable full history Secret Detection, set the variable `SECRET_DETECTION_HISTORIC_SCAN` to `true` in your `.gitlab-ci.yml` file.

## Custom rulesets **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/211387) in GitLab 13.5.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/339614) support for passthrough chains.
>   Expanded to include additional passthrough types of `file`, `git`, and `url` in GitLab 14.6.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/235359) support for overriding rules in
>   GitLab 14.8.

You can customize the default Secret Detection rules provided with GitLab.

The following customization options can be used separately, or in combination:

- [Disable predefined rules](#disable-predefined-analyzer-rules).
- [Override predefined rules](#override-predefined-analyzer-rules).
- [Synthesize a custom configuration](#synthesize-a-custom-configuration).

### Disable predefined analyzer rules

If there are specific Secret Detection rules that you don't want active, you can disable them.

To disable analyzer rules:

1. Create a `.gitlab` directory at the root of your project, if one doesn't already exist.
1. Create a custom ruleset file named `secret-detection-ruleset.toml` in the `.gitlab` directory, if
   one doesn't already exist.
1. Set the `disabled` flag to `true` in the context of a `ruleset` section.
1. In one or more `ruleset.identifier` subsections, list the rules to disable. Every
   `ruleset.identifier` section has:
   - A `type` field for the predefined rule identifier.
   - A `value` field for the rule name.

In the following example `secret-detection-ruleset.toml` file, the disabled rules are assigned to
`secrets` by matching the `type` and `value` of identifiers:

```toml
[secrets]
  [[secrets.ruleset]]
    disable = true
    [secrets.ruleset.identifier]
      type = "gitleaks_rule_id"
      value = "RSA private key"
```

### Override predefined analyzer rules

If there are specific Secret Detection rules you want to customize, you can override them. For
example, you might increase the severity of specific secrets.

To override rules:

1. Create a `.gitlab` directory at the root of your project, if one doesn't already exist.
1. Create a custom ruleset file named `secret-detection-ruleset.toml` in the `.gitlab` directory, if
   one doesn't already exist.
1. In one or more `ruleset.identifier` subsections, list the rules to override. Every
   `ruleset.identifier` section has:
   - A `type` field for the predefined rule identifier.
   - A `value` field for the rule name.
1. In the `ruleset.override` context of a `ruleset` section,
   provide the keys to override. Any combination of keys can be
   overridden. Valid keys are:
   - description
   - message
   - name
   - severity (valid options are: Critical, High, Medium, Low, Unknown, Info)

In the following example `secret-detection-ruleset.toml` file, rules are matched by the `type` and
`value` of identifiers and then overridden:

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

### Synthesize a custom configuration

To create a custom configuration, you can use passthrough chains. Passthroughs can also be chained
to build more complex configurations. For more details, see
[SAST Customize ruleset](../sast/customize_rulesets.md).

Only the following passthrough types are supported by the `secrets` analyzer:

- `file`
- `raw`

In the `secret-detection-ruleset.toml` file, do one of the following:

- Define a custom ruleset, for example:

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

- Provide the name of the file containing a custom ruleset, for example:

  ```toml
  [secrets]
    description = 'secrets custom rules configuration'

    [[secrets.passthrough]]
      type  = "file"
      target = "gitleaks.toml"
      value = "config/gitleaks.toml"
  ```

## Running Secret Detection in an offline environment **(PREMIUM SELF)**

An offline environment has limited, restricted, or intermittent access to external resources through
the internet. For self-managed GitLab instances in such an environment, Secret Detection requires
some configuration changes. The instructions in this section must be completed together with the
instructions detailed in [offline environments](../offline_deployments/index.md).

### Configure GitLab Runner

By default, a runner tries to pull Docker images from the GitLab container registry even if a local
copy is available. You should use this default setting, to ensure Docker images remain current.
However, if no network connectivity is available, you must change the default GitLab Runner
`pull_policy` variable.

Configure the GitLab Runner CI/CD variable `pull_policy` to
[`if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy).

### Use local Secret Detection analyzer image

Use a local Secret Detection analyzer image if you want to obtain the image from a local Docker
registry instead of the GitLab container registry.

Prerequisites:

- Importing Docker images into a local offline Docker registry depends on your
  network security policy. Consult your IT staff to find an accepted and approved process
  to import or temporarily access external resources.

1. Import the default Secret Detection analyzer image from `registry.gitlab.com` into your
   [local Docker container registry](../../packages/container_registry/index.md):

   ```plaintext
   registry.gitlab.com/security-products/secrets:4
   ```

   The Secret Detection analyzer's image is [periodically updated](../index.md#vulnerability-scanner-maintenance)
   so you should periodically update the local copy.

1. Set the CI/CD variable `SECURE_ANALYZERS_PREFIX` to the local Docker container registry.

   ```yaml
   include:
     - template: Security/Secret-Detection.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
   ```

The Secret Detection job should now use the local copy of the Secret Detection analyzer Docker
image, without requiring internet access.

### Configure a custom Certificate Authority

To trust a custom Certificate Authority, set the `ADDITIONAL_CA_CERT_BUNDLE` variable to the bundle
of CA certificates that you trust. Do this either in the `.gitlab-ci.yml` file, in a file
variable, or as a CI/CD variable.

- In the `.gitlab-ci.yml` file, the `ADDITIONAL_CA_CERT_BUNDLE` value must contain the
  [text representation of the X.509 PEM public-key certificate](https://www.rfc-editor.org/rfc/rfc7468#section-5.1).

  For example:

  ```yaml
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
        -----BEGIN CERTIFICATE-----
        MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
        ...
        jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
        -----END CERTIFICATE-----
  ```

- If using a file variable, set the value of `ADDITIONAL_CA_CERT_BUNDLE` to the path to the
  certificate.

- If using a variable, set the value of `ADDITIONAL_CA_CERT_BUNDLE` to the text
  representation of the certificate.

## Troubleshooting

### Set the logging level

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10880) in GitLab 13.1.

Set the logging level to `debug` when you need diagnostic information in a Secret Detection job log.

WARNING:
Debug logging can be a serious security risk. The output may contain the content of environment
variables and other secrets available to the job. The output is uploaded to the GitLab server and
visible in job logs.

1. In the `.gitlab-ci.yml` file, set the `SECURE_LOG_LEVEL` CI/CD variable to `debug`.
1. Run the Secret Detection job.
1. Analyze the content of the Secret Detection job.
1. In the `.gitlab-ci.yml` file, set the `SECURE_LOG_LEVEL` CI/CD variable to `info` (default).

### Warning: `gl-secret-detection-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../ci/pipelines/job_artifacts.md#error-message-no-files-to-upload).

### Error: `Couldn't run the gitleaks command: exit status 2`

The Secret Detection analyzer relies on generating patches between commits to scan content for
secrets. If the number of commits in a merge request is greater than the value of the
[`GIT_DEPTH` CI/CD variable](../../../ci/runners/configure_runners.md#shallow-cloning), Secret
Detection [fails to detect secrets](#error-couldnt-run-the-gitleaks-command-exit-status-2).

For example, you could have a pipeline triggered from a merge request containing 60 commits and the
`GIT_DEPTH` variable set to less than 60. In that case the Secret Detection job fails because the
clone is not deep enough to contain all of the relevant commits. To verify the current value, see
[pipeline configuration](../../../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone).

To confirm this as the cause of the error, set the [logging level](#set-the-logging-level) to
`debug`, then rerun the pipeline. The logs should look similar to the following example. The text
"object not found" is a symptom of this error.

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

### Error: `ERR fatal: ambiguous argument`

Secret Detection can fail with the message `ERR fatal: ambiguous argument` error if your
repository's default branch is unrelated to the branch the job was triggered for. See issue
[!352014](https://gitlab.com/gitlab-org/gitlab/-/issues/352014) for more details.

To resolve the issue, make sure to correctly [set your default branch](../../project/repository/branches/default.md#change-the-default-branch-name-for-a-project)
on your repository. You should set it to a branch that has related history with the branch you run
the `secret-detection` job on.
