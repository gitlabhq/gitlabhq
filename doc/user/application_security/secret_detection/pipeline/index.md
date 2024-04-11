---
stage: Secure
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---
<!-- markdownlint-disable MD025 -->

# Pipeline secret detection

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** GA

Pipeline secret detection scans committed files after they has been pushed to GitLab.

After you [enable Pipeline Secret Detection](#enabling-the-analyzer), scans run in a CI/CD job named `secret_detection`.
You can run scans and view [Pipeline Secret Detection JSON report artifacts](../../../../ci/yaml/artifacts_reports.md#artifactsreportssecret_detection) in any GitLab tier.

With GitLab Ultimate, Pipeline Secret Detection results are also processed so you can:

- See them in the [merge request widget](../../index.md#merge-request), [pipeline security report](../../vulnerability_report/pipeline.md), and [vulnerability report](../../vulnerability_report/index.md) UIs.
- Use them in approval workflows.
- Review them in the security dashboard.
- [Automatically respond](../automatic_response.md) to leaks in public repositories.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> For an interactive reading and how-to demo of this Pipeline Secret Detection documentation see:

- [How to enable secret detection in GitLab Application Security Part 1/2](https://youtu.be/dbMxeO6nJCE?feature=shared)
- [How to enable secret detection in GitLab Application Security Part 2/2](https://youtu.be/VL-_hdiTazo?feature=shared)

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> For other interactive reading and how-to demos, see the [Get Started With GitLab Application Security Playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9).

## Detected secrets

GitLab maintains the detection rules used in Pipeline Secret Detection.
The [default ruleset](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/gitleaks.toml)
contains more than 100 patterns.

Most Pipeline Secret Detection patterns search for specific types of secrets.
Many services add prefixes or other structural details to their secrets so they can be identified if they're leaked.
For example, GitLab [adds a `glpat-` prefix](../../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix) to project, group, and personal access tokens by default.

To provide more reliable, high-confidence results, Pipeline Secret Detection only looks for passwords or other unstructured secrets in specific contexts like URLs.

## Coverage

Pipeline Secret Detection scans different aspects of your code, depending on the situation. For all methods
except "Default branch", Pipeline Secret Detection scans commits, not the working tree. For example,
Pipeline Secret Detection can detect if a secret was added in one commit and removed in a later commit.

- Historical scan

  If the `SECRET_DETECTION_HISTORIC_SCAN` variable is set, the content of all
  [branches](../../../project/repository/branches/index.md) is scanned. Before scanning the
  repository's content, Pipeline Secret Detection runs the command `git fetch --all` to fetch the content of all
  branches.

- Commit range

  If the `SECRET_DETECTION_LOG_OPTIONS` variable is set, the secrets analyzer fetches the entire
  history of the branch or reference the pipeline is being run for. Pipeline Secret Detection then runs,
  scanning the commit range specified.

- Default branch

  When Pipeline Secret Detection is run on the default branch, the Git repository is treated as a plain
  folder. Only the contents of the repository at the current HEAD are scanned. Commit history is not scanned.

- Push event

  On a push event, Pipeline Secret Detection determines what commit range to scan, given the information
  available in the runner. To determine the commit range, the variables `CI_COMMIT_SHA` and
  `CI_COMMIT_BEFORE_SHA` are important.

  - `CI_COMMIT_SHA` is the commit at HEAD for a given branch. This variable is always set for push events.
  - `CI_COMMIT_BEFORE_SHA` is set in most cases. However, it is not set for the first push event on
    a new branch, nor for merge pipelines. Because of this, Pipeline Secret Detection can't be guaranteed
    when multiple commits are committed to a new branch.

- Merge request

  In a merge request, Pipeline Secret Detection scans every commit made on the source branch. To use this
  feature, you must use the [`latest` Pipeline Secret Detection template](../../index.md#use-security-scanning-tools-with-merge-request-pipelines), as it supports
  [merge request pipelines](../../../../ci/pipelines/merge_request_pipelines.md). Pipeline Secret Detection's
  results are only available after the pipeline is completed.

## Full history Pipeline Secret Detection

By default, Pipeline Secret Detection scans only the current state of the Git repository. Any secrets
contained in the repository's history are not detected. To address this, Pipeline Secret Detection can
scan the Git repository's full history.

You should do a full history scan only once, after enabling Pipeline Secret Detection. A full history
can take a long time, especially for larger repositories with lengthy Git histories. After
completing an initial full history scan, use only standard Pipeline Secret Detection as part of your
pipeline.

## Configuration

### Requirements

Prerequisites:

- Linux-based GitLab Runner with the [`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
  [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor. If you're using the
  shared runners on GitLab.com, this is enabled by default.
  - Windows Runners are not supported.
  - CPU architectures other than amd64 are not supported.
- If you use your own runners, make sure the Docker version installed is **not** `19.03.0`. See
  [Docker error](../../sast/troubleshooting.md#docker-error)
  for details.
- GitLab CI/CD configuration (`.gitlab-ci.yml`) must include the `test` stage.

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/).

| Capability                                                                                           | In Free & Premium      | In Ultimate            |
|:-----------------------------------------------------------------------------------------------------|:-----------------------|:-----------------------|
| [Configure Pipeline Secret Detection scanner](#enabling-the-analyzer)                                       | **{check-circle}** Yes | **{check-circle}** Yes |
| [Customize Pipeline Secret Detection settings](#customizing-analyzer-settings)                                      | **{check-circle}** Yes | **{check-circle}** Yes |
| Download [SAST output](../../sast/index.md#output)                                                      | **{check-circle}** Yes | **{check-circle}** Yes |
| [Check text for potential secrets](#warnings-for-potential-leaks-in-text-content) before it's posted | **{check-circle}** Yes | **{check-circle}** Yes |
| See new findings in the merge request widget                                                         | **{dotted-circle}** No | **{check-circle}** Yes |
| View identified secrets in the pipelines' **Security** tab                                           | **{dotted-circle}** No | **{check-circle}** Yes |
| [Manage vulnerabilities](../../vulnerability_report/index.md)                                           | **{dotted-circle}** No | **{check-circle}** Yes |
| [Access the Security Dashboard](../../security_dashboard/index.md)                                      | **{dotted-circle}** No | **{check-circle}** Yes |
| [Customize Pipeline Secret Detection rulesets](#custom-rulesets)                                              | **{dotted-circle}** No | **{check-circle}** Yes |

### Enabling the analyzer

To enable Pipeline Secret Detection, either:

- Enable [Auto DevOps](../../../../topics/autodevops/index.md), which includes [Auto Pipeline Secret Detection](../../../../topics/autodevops/stages.md#auto-secret-detection).

- [Edit the `.gitlab-ci.yml` file manually](#edit-the-gitlab-ciyml-file-manually). Use this method
  if your `.gitlab-ci.yml` file is complex.

- [Use an automatically configured merge request](#use-an-automatically-configured-merge-request).

#### Edit the `.gitlab-ci.yml` file manually

This method requires you to manually edit the existing `.gitlab-ci.yml` file. Use this method if
your GitLab CI/CD configuration file is complex.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline editor**.
1. Copy and paste the following to the bottom of the `.gitlab-ci.yml` file:

   ```yaml
   include:
     - template: Jobs/Secret-Detection.gitlab-ci.yml
   ```

1. Select the **Validate** tab, then select **Validate pipeline**.
   The message **Simulation completed successfully** indicates the file is valid.
1. Select the **Edit** tab.
1. Optional. In the **Commit message** text box, customize the commit message.
1. In the **Branch** text box, enter the name of the default branch.
1. Select **Commit changes**.

Pipelines now include a Pipeline Secret Detection job.

#### Use an automatically configured merge request

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4496) in GitLab 13.11, deployed behind a feature flag, enabled by default.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/329886) in GitLab 14.1.

This method automatically prepares a merge request, with the Pipeline Secret Detection template included in
the `.gitlab-ci.yml` file. You then merge the merge request to enable Pipeline Secret Detection.

NOTE:
This method works best with no existing `.gitlab-ci.yml` file, or with a minimal configuration
file. If you have a complex GitLab configuration file it may not be parsed successfully, and an
error may occur. In that case, use the [manual](#edit-the-gitlab-ciyml-file-manually) method instead.

To enable Pipeline Secret Detection:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Pipeline Secret Detection** row, select **Configure with a merge request**.
1. Optional. Complete the fields.
1. Select **Create merge request**.
1. Review and merge the merge request.

Pipelines now include a Pipeline Secret Detection job.

### Customizing analyzer settings

The Pipeline Secret Detection scan settings can be changed through [CI/CD variables](#available-cicd-variables)
by using the [`variables`](../../../../ci/yaml/index.md#variables) parameter in `.gitlab-ci.yml`.

WARNING:
All configuration of GitLab security scanning tools should be tested in a merge request before
merging these changes to the default branch. Failure to do so can give unexpected results,
including a large number of false positives.

#### Adding new patterns

To search for other types of secrets in your repositories, you can configure a [custom ruleset](#custom-rulesets).

To propose a new detection rule for all users of Pipeline Secret Detection, create a merge request against the [file containing the default rules](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/gitleaks.toml).

If you operate a cloud or SaaS product and you're interested in partnering with GitLab to better protect your users, learn more about our [partner program for leaked credential notifications](../automatic_response.md#partner-program-for-leaked-credential-notifications).

#### Ignore secrets

In some instances, you might want to ignore a secret. For example, you may have a fake secret in an
example or a test suite. In these instances, you want to ignore the secret, instead of having it
reported as a vulnerability.

To ignore a secret, add `gitleaks:allow` as a comment to the line that contains the secret.

For example:

```ruby
 "A personal token for GitLab will look like glpat-JUST20LETTERSANDNUMB" #gitleaks:allow
```

#### Pinning to specific analyzer version

The GitLab-managed CI/CD template specifies a major version and automatically pulls the latest analyzer release within that major version.

In some cases, you may need to use a specific version.
For example, you might need to avoid a regression in a later release.

To override the automatic update behavior, set the `SECRETS_ANALYZER_VERSION` CI/CD variable
in your CI/CD configuration file after you include the [`Secret-Detection.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml).

You can set the tag to:

- A major version, like `4`. Your pipelines use any minor or patch updates that are released within this major version.
- A minor version, like `4.5`. Your pipelines use any patch updates that are released within this minor version.
- A patch version, like `4.5.0`. Your pipelines don't receive any updates.

This example uses a specific minor version of the analyzer:

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRETS_ANALYZER_VERSION: "4.5"
```

#### Extending the default configuration

You can extend the default configuration with additional changes by using [Gitleaks `extend` support](https://github.com/gitleaks/gitleaks#configuration).

In the following `file` passthrough example, the string `glpat-1234567890abcdefghij` is ignored by Pipeline Secret Detection. That GitLab personal access token (PAT) is used in test cases. Detection of it would be a false positive.

The `secret-detection-ruleset.toml` file defines that the configuration in `extended-gitleaks-config.toml` file is to be included. The `extended-gitleaks-config.toml` file defines the custom Gitleaks configuration. The `allowlist` stanza defines a regular expression that matches the secret that is to be ignored ("allowed").

```toml
### .gitlab/secret-detection-ruleset.toml
[secrets]
  description = 'secrets custom rules configuration'

  [[secrets.passthrough]]
    type  = "file"
    target = "gitleaks.toml"
    value = "extended-gitleaks-config.toml"
```

```toml
### extended-gitleaks-config.toml
title = "extension of gitlab's default gitleaks config"

[extend]
### Extends default packaged path
path = "/gitleaks.toml"

[allowlist]
  description = "allow list of test tokens to ignore in detection"
  regexTarget = "match"
  regexes = [
    '''glpat-1234567890abcdefghij''',
  ]
```

#### Enable full history Pipeline Secret Detection

To enable full history Pipeline Secret Detection, set the variable `SECRET_DETECTION_HISTORIC_SCAN` to `true` in your `.gitlab-ci.yml` file.

#### Running jobs in merge request pipelines

See [Use security scanning tools with merge request pipelines](../../index.md#use-security-scanning-tools-with-merge-request-pipelines).

#### Custom rulesets

DETAILS:
**Tier:** Ultimate

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/211387) in GitLab 13.5.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/339614) support for passthrough chains.
>   Expanded to include additional passthrough types of `file`, `git`, and `url` in GitLab 14.6.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/235359) support for overriding rules in
>   GitLab 14.8.

You can customize which [secrets are reported in the GitLab UI](#pipeline-secret-detection).
However, the `secret_detection` job logs always include the number
of secrets detected by the default Pipeline Secret Detection rules.

The following customization options can be used separately, or in combination (except for disabling or overriding rules when using a remote configuration file):

- [Disable predefined rules](#disable-predefined-analyzer-rules).
- [Override predefined rules](#override-predefined-analyzer-rules).
- [Synthesize a custom configuration](#synthesize-a-custom-configuration).
- [Specify a remote configuration file](#specify-a-remote-configuration-file).

#### Synthesize a custom configuration

You can use passthroughs to override the default Pipeline Secret Detection ruleset. The
following passthrough types are supported by the `secrets` analyzer:

- `raw`
- `file`

To define a passthrough, add _one_ of the following to the
`secret-detection-ruleset.toml` file:

- Using an inline (`raw`) value:

  ```toml
  [secrets]
    description = 'secrets custom rules configuration'

    [[secrets.passthrough]]
      type  = "raw"
      target = "gitleaks.toml"
      value = """\
  title = "gitleaks config"
  ### add regexes to the regex table
  [[rules]]
  description = "Test for Raw Custom Rulesets"
  regex = '''Custom Raw Ruleset T[est]{3}'''
  """
  ```

- Using an external `file` committed to the current repository:

  ```toml
  [secrets]
    description = 'secrets custom rules configuration'

    [[secrets.passthrough]]
      type  = "file"
      target = "gitleaks.toml"
      value = "config/gitleaks.toml"
  ```

For more information on the syntax of passthroughs, see the
[passthroughs section on the SAST customize rulesets](../../sast/customize_rulesets.md#the-analyzerpassthrough-section)
page.

#### Specify a remote configuration file

Projects can be configured with a [CI/CD variable](../../../../ci/variables/index.md) in order
to specify a ruleset configuration outside of the current repository.

The `SECRET_DETECTION_RULESET_GIT_REFERENCE` variable uses an SCP-style syntax for specifying a URI,
optional authentication, and optional Git SHA. The variable uses the following format:

```plaintext
<AUTH_USER>:<AUTH_PASSWORD>@<PROJECT_PATH>@<GIT_SHA>
```

NOTE:
A local `.gitlab/secret-detection-ruleset.toml` file in the project takes precedence over `SECRET_DETECTION_RULESET_GIT_REFERENCE`.

The following example includes the Pipeline Secret Detection template in a project to be scanned and specifies
the `SECRET_DETECTION_RULESET_GIT_REFERENCE` variable for referencing a separate project configuration.

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

variables:
  SECRET_DETECTION_RULESET_GIT_REFERENCE: "gitlab.com/example-group/example-ruleset-project"
```

For more information on the syntax of remote configurations, see the
[specify a private remote configuration example](../../sast/customize_rulesets.md#specify-a-private-remote-configuration)
on the SAST customize rulesets page.

### Overriding the analyzer jobs

To override a job definition, (for example, change properties like `variables` or `dependencies`),
declare a job with the same name as the secret detection job to override. Place this new job after
the template inclusion and specify any additional keys under it.

In the following example _extract_ of a `.gitlab-ci.yml` file:

- The Pipeline Secret Detection template is [included](../../../../ci/yaml/index.md#include).
- In the `secret_detection` job, the CI/CD variable `SECRET_DETECTION_HISTORIC_SCAN` is set to
  `true`. Because the template is evaluated before the pipeline configuration, the last mention of
  the variable takes precedence.

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_HISTORIC_SCAN: "true"
```

#### Override predefined analyzer rules

WARNING:
Overriding rules does not currently work when using a [remote configuration file](#specify-a-remote-configuration-file).
[Issue 425251](https://gitlab.com/gitlab-org/gitlab/-/issues/425251) proposes to fix this limitation.

If there are specific Pipeline Secret Detection rules you want to customize, you can override them. For
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

#### Disable predefined analyzer rules

WARNING:
Disabling rules does not currently work when using a [remote configuration file](#specify-a-remote-configuration-file).
[Issue 425251](https://gitlab.com/gitlab-org/gitlab/-/issues/425251) proposes to fix this limitation.

If there are specific Pipeline Secret Detection rules that you don't want active, you can disable them.

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

### Available CI/CD variables

Pipeline Secret Detection can be customized by defining available CI/CD variables:

| CI/CD variable                    | Default value | Description |
|-----------------------------------|---------------|-------------|
| `SECRET_DETECTION_EXCLUDED_PATHS` | ""            | Exclude vulnerabilities from output based on the paths. The paths are a comma-separated list of patterns. Patterns can be globs (see [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) for supported patterns), or file or folder paths (for example, `doc,spec` ). Parent directories also match patterns. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225273) in GitLab 13.3. |
| `SECRET_DETECTION_HISTORIC_SCAN`  | false         | Flag to enable a historic Gitleaks scan. |
| `SECRET_DETECTION_IMAGE_SUFFIX`   | "" | Suffix added to the image name. If set to `-fips`, `FIPS-enabled` images are used for scan. See [Use FIPS-enabled images](#fips-enabled-images) for more details. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355519) in GitLab 14.10. |
| `SECRET_DETECTION_LOG_OPTIONS`  | ""         | [`git log`](https://git-scm.com/docs/git-log) options used to define commit ranges. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350660) in GitLab 15.1.|

In previous GitLab versions, the following variables were also available:

| CI/CD variable                    | Default value | Description |
|-----------------------------------|---------------|-------------|
| `SECRET_DETECTION_COMMIT_FROM`    | -             | The commit a Gitleaks scan starts at. [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) in GitLab 13.5. Replaced with `SECRET_DETECTION_COMMITS`. |
| `SECRET_DETECTION_COMMIT_TO`      | -             | The commit a Gitleaks scan ends at. [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) in GitLab 13.5. Replaced with `SECRET_DETECTION_COMMITS`. |
| `SECRET_DETECTION_COMMITS`        | -             | The list of commits that Gitleaks should scan. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) in GitLab 13.5. [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/352565) in GitLab 15.0. |

### Offline configuration

DETAILS:
**Tier:** PREMIUM
**Offering:** Self-managed

An offline environment has limited, restricted, or intermittent access to external resources through
the internet. For self-managed GitLab instances in such an environment, Pipeline Secret Detection requires
some configuration changes. The instructions in this section must be completed together with the
instructions detailed in [offline environments](../../offline_deployments/index.md).

#### Configure GitLab Runner

By default, a runner tries to pull Docker images from the GitLab container registry even if a local
copy is available. You should use this default setting, to ensure Docker images remain current.
However, if no network connectivity is available, you must change the default GitLab Runner
`pull_policy` variable.

Configure the GitLab Runner CI/CD variable `pull_policy` to
[`if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy).

#### Use local Pipeline Secret Detection analyzer image

Use a local Pipeline Secret Detection analyzer image if you want to obtain the image from a local Docker
registry instead of the GitLab container registry.

Prerequisites:

- Importing Docker images into a local offline Docker registry depends on your
  network security policy. Consult your IT staff to find an accepted and approved process
  to import or temporarily access external resources.

1. Import the default Pipeline Secret Detection analyzer image from `registry.gitlab.com` into your
   [local Docker container registry](../../../packages/container_registry/index.md):

   ```plaintext
   registry.gitlab.com/security-products/secrets:4
   ```

   The Pipeline Secret Detection analyzer's image is [periodically updated](../../index.md#vulnerability-scanner-maintenance)
   so you should periodically update the local copy.

1. Set the CI/CD variable `SECURE_ANALYZERS_PREFIX` to the local Docker container registry.

   ```yaml
   include:
     - template: Jobs/Secret-Detection.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
   ```

The Pipeline Secret Detection job should now use the local copy of the Secret Detection analyzer Docker
image, without requiring internet access.

### Using a custom SSL CA certificate authority

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

## FIPS-enabled images

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6479) in GitLab 14.10.

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
  - template: Jobs/Secret-Detection.gitlab-ci.yml
```

## Troubleshooting

### Debug-level logging

Debug-level logging can help when troubleshooting. For details, see
[debug-level logging](../../troubleshooting_application_security.md#debug-level-logging).

#### Warning: `gl-secret-detection-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload).

#### Error: `Couldn't run the gitleaks command: exit status 2`

The Pipeline Secret Detection analyzer relies on generating patches between commits to scan content for
secrets. If the number of commits in a merge request is greater than the value of the
[`GIT_DEPTH` CI/CD variable](../../../../ci/runners/configure_runners.md#shallow-cloning), Secret
Detection [fails to detect secrets](#error-couldnt-run-the-gitleaks-command-exit-status-2).

For example, you could have a pipeline triggered from a merge request containing 60 commits and the
`GIT_DEPTH` variable set to less than 60. In that case the Pipeline Secret Detection job fails because the
clone is not deep enough to contain all of the relevant commits. To verify the current value, see
[pipeline configuration](../../../../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone).

To confirm this as the cause of the error, enable [debug-level logging](../../troubleshooting_application_security.md#debug-level-logging),
then rerun the pipeline. The logs should look similar to the following example. The text
"object not found" is a symptom of this error.

```plaintext
ERRO[2020-11-18T18:05:52Z] object not found
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Couldn't run the gitleaks command: exit status 2
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Gitleaks analysis failed: exit status 2
```

To resolve the issue, set the [`GIT_DEPTH` CI/CD variable](../../../../ci/runners/configure_runners.md#shallow-cloning)
to a higher value. To apply this only to the Pipeline Secret Detection job, the following can be added to
your `.gitlab-ci.yml` file:

```yaml
secret_detection:
  variables:
    GIT_DEPTH: 100
```

#### Error: `ERR fatal: ambiguous argument`

Pipeline Secret Detection can fail with the message `ERR fatal: ambiguous argument` error if your
repository's default branch is unrelated to the branch the job was triggered for. See issue
[!352014](https://gitlab.com/gitlab-org/gitlab/-/issues/352014) for more details.

To resolve the issue, make sure to correctly [set your default branch](../../../project/repository/branches/default.md#change-the-default-branch-name-for-a-project)
on your repository. You should set it to a branch that has related history with the branch you run
the `secret-detection` job on.

#### `exec /bin/sh: exec format error` message in job log

The GitLab Pipeline Secret Detection analyzer [only supports](#enabling-the-analyzer) running on the `amd64` CPU architecture.
This message indicates that the job is being run on a different architecture, such as `arm`.

## Warnings

### Responding to a leaked secret

When a secret is detected, you should rotate it immediately. GitLab attempts to
[automatically revoke](../automatic_response.md) some types of leaked secrets. For those that are not
automatically revoked, you must do so manually.

[Purging a secret from the repository's history](../../../project/repository/reducing_the_repo_size_using_git.md#purge-files-from-repository-history)
does not fully address the leak. The original secret remains in any existing forks or
clones of the repository.

### Warnings for potential leaks in text content

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368434) in GitLab 15.11.
> - Detection of personal access tokens with a custom prefix was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/411146) in GitLab 16.1. GitLab self-managed only.

When you create an issue, propose a merge request, or write a comment, you might accidentally post a sensitive value.
For example, you might paste in the details of an API request or an environment variable that contains an authentication token.

GitLab checks if the text of your issue description, merge request description, comment, or reply contains a sensitive token.
If a token is found, a warning message is displayed. You can then edit your message before posting it.
This check happens in your browser before the message is sent to the server.
The check is always on; you don't have to set it up.

Your text is checked for the following secret types:

- GitLab [personal access tokens](../../../../security/token_overview.md#personal-access-tokens)
  - If a [personal access token prefix](../../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix) has been configured, a token using this prefix is checked.
- GitLab [feed tokens](../../../../security/token_overview.md#feed-token)

This feature is separate from Pipeline Secret Detection scanning, which checks your Git repository for leaked secrets.
[Issue 405147](https://gitlab.com/gitlab-org/gitlab/-/issues/405147) tracks efforts to align these two types of protection.

<!-- markdownlint-enable MD025 -->
