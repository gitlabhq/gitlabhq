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

People sometimes accidentally commit secrets like keys or API tokens to Git repositories.
After a sensitive value is pushed to a remote repository, anyone with access to the repository can impersonate the authorized user of the secret for malicious purposes.
Most organizations require exposed secrets to be revoked and replaced to address this risk.

Secret Detection scans your repository to help prevent your secrets from being exposed.
Secret Detection scanning works on all text files, regardless of the language or framework used.

After you [enable Secret Detection](#enable-secret-detection), scans run in a CI/CD job named `secret_detection`.
You can run scans and view [Secret Detection JSON report artifacts](../../../ci/yaml/artifacts_reports.md#artifactsreportssecret_detection) in any GitLab tier.

With GitLab Ultimate, Secret Detection results are also processed so you can:

- See them in the [merge request widget](../index.md#view-security-scan-information-in-merge-requests), [pipeline security report](../vulnerability_report/pipeline.md), and [Vulnerability Report](../vulnerability_report/index.md).
- Use them in approval workflows.
- Review them in the security dashboard.
- [Automatically respond](post_processing.md) to leaks in public repositories.

## Detected secrets

GitLab maintains the detection rules used in Secret Detection.
The [default ruleset](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/gitleaks.toml)
contains more than 100 patterns.

Most Secret Detection patterns search for specific types of secrets.
Many services add prefixes or other structural details to their secrets so they can be identified if they're leaked.
For example, GitLab [adds a `glpat-` prefix](../../admin_area/settings/account_and_limit_settings.md#personal-access-token-prefix) to project, group, and project access tokens by default.

To provide more reliable, high-confidence results, Secret Detection only looks for passwords or other unstructured secrets in specific contexts like URLs.

### Adding new patterns

To search for other types of secrets in your repositories, you can configure a [custom ruleset](#custom-rulesets).

To propose a new detection rule for all users of Secret Detection, create a merge request against the [file containing the default rules](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/gitleaks.toml).

If you operate a cloud or SaaS product and you're interested in partnering with GitLab to better protect your users, learn more about our [partner program for leaked credential notifications](post_processing.md#partner-program-for-leaked-credential-notifications).

## Features per tier

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/).

| Capability                                                       | In Free & Premium      | In Ultimate            |
|:---------------------------------------------------------------- |:-----------------------|:-----------------------|
| [Configure Secret Detection scanner](#enable-secret-detection)   | **{check-circle}** Yes | **{check-circle}** Yes |
| [Customize Secret Detection settings](#configure-scan-settings)  | **{check-circle}** Yes | **{check-circle}** Yes |
| Download [JSON Report](../sast/index.md#reports-json-format)     | **{check-circle}** Yes | **{check-circle}** Yes |
| [Check text for potential secrets](#warnings-for-potential-leaks-in-text-content) before it's posted | **{check-circle}** Yes | **{check-circle}** Yes |
| See new findings in the merge request widget                     | **{dotted-circle}** No | **{check-circle}** Yes |
| View identified secrets in the pipelines' **Security** tab       | **{dotted-circle}** No | **{check-circle}** Yes |
| [Manage vulnerabilities](../vulnerability_report/index.md)       | **{dotted-circle}** No | **{check-circle}** Yes |
| [Access the Security Dashboard](../security_dashboard/index.md)  | **{dotted-circle}** No | **{check-circle}** Yes |
| [Customize Secret Detection rulesets](#custom-rulesets)          | **{dotted-circle}** No | **{check-circle}** Yes |

## Coverage

Secret Detection scans different aspects of your code, depending on the situation. For all methods
except "Default branch", Secret Detection scans commits, not the working tree. For example,
Secret Detection can detect if a secret was added in one commit and removed in a later commit.

- Historical scan

  If the `SECRET_DETECTION_HISTORIC_SCAN` variable is set, the content of all
  [branches](../../project/repository/branches/index.md) is scanned. Before scanning the
  repository's content, Secret Detection runs the command `git fetch --all` to fetch the content of all
  branches.

- Commit range

  If the `SECRET_DETECTION_LOG_OPTS` variable is set, the secrets analyzer fetches the entire
  history of the branch or reference the pipeline is being run for. Secret Detection then runs,
  scanning the commit range specified.

- Default branch

  When Secret Detection is run on the default branch, the Git repository is treated as a plain
  folder. Only the contents of the repository at the current HEAD are scanned. Commit history is not scanned.

- Push event

  On a push event, Secret Detection determines what commit range to scan, given the information
  available in the runner. To determine the commit range, the variables `CI_COMMIT_SHA` and
  `CI_COMMIT_BEFORE_SHA` are important.

  - `CI_COMMIT_SHA` is the commit at HEAD for a given branch. This variable is always set for push events.
  - `CI_COMMIT_BEFORE_SHA` is set in most cases. However, it is not set for the first push event on
    a new branch, nor for merge pipelines. Because of this, Secret Detection can't be guaranteed
    when multiple commits are committed to a new branch.

- Merge request

  In a merge request, Secret Detection scans every commit made on the source branch. To use this
  feature, you must use the [`latest` Secret Detection template](#templates), as it supports
  [merge request pipelines](../../../ci/pipelines/merge_request_pipelines.md).

## Templates

Secret Detection default configuration is defined in CI/CD templates. Updates to the template are
provided with GitLab upgrades, allowing you to benefit from any improvements and additions.

Available templates:

- [`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml): Stable version of the Secret Detection CI/CD template.
- [`Secret-Detection.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.latest.gitlab-ci.yml): Latest version of the Secret Detection template.

WARNING:
The latest version of the template may include breaking changes. Use the stable template unless you
need a feature provided only in the latest template.

For more information about template versioning, see the
[CI/CD documentation](../../../development/cicd/templates.md#latest-version).

## Enable Secret Detection

Prerequisites:

- Linux-based GitLab Runner with the [`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor. If you're using the
shared runners on GitLab.com, this is enabled by default.
  - Windows Runners are not supported.
  - CPU architectures other than amd64 are not supported.
- If you use your own runners, make sure the Docker version installed is **not** `19.03.0`. See
  [troubleshooting information](../sast#error-response-from-daemon-error-processing-tar-file-docker-tar-relocation-error)
  for details.
- GitLab CI/CD configuration (`.gitlab-ci.yml`) must include the `test` stage.

To enable Secret Detection, either:

- Enable [Auto DevOps](../../../topics/autodevops/index.md), which includes [Auto Secret Detection](../../../topics/autodevops/stages.md#auto-secret-detection).

- [Edit the `.gitlab-ci.yml` file manually](#edit-the-gitlab-ciyml-file-manually). Use this method
  if your `.gitlab-ci.yml` file is complex.

- [Use an automatically configured merge request](#use-an-automatically-configured-merge-request).

### Edit the `.gitlab-ci.yml` file manually

This method requires you to manually edit the existing `.gitlab-ci.yml` file. Use this method if
your GitLab CI/CD configuration file is complex.

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **CI/CD > Editor**.
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

Pipelines now include a Secret Detection job.

### Use an automatically configured merge request

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4496) in GitLab 13.11, deployed behind a feature flag, enabled by default.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/329886) in GitLab 14.1.

This method automatically prepares a merge request, with the Secret Detection template included in
the `.gitlab-ci.yml` file. You then merge the merge request to enable Secret Detection.

NOTE:
This method works best with no existing `.gitlab-ci.yml` file, or with a minimal configuration
file. If you have a complex GitLab configuration file it may not be parsed successfully, and an
error may occur. In that case, use the [manual](#edit-the-gitlab-ciyml-file-manually) method instead.

To enable Secret Detection:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Security and Compliance > Security configuration**.
1. In the **Secret Detection** row, select **Configure with a merge request**.
1. Optional. Complete the fields.
1. Select **Create merge request**.
1. Review and merge the merge request.

Pipelines now include a Secret Detection job.

## Responding to a leaked secret

When a secret is detected, you should rotate it immediately. GitLab attempts to
[automatically revoke](post_processing.md) some types of leaked secrets. For those that are not
automatically revoked, you must do so manually.

[Purging a secret from the repository's history](../../project/repository/reducing_the_repo_size_using_git.md#purge-files-from-repository-history)
does not fully address the leak. The original secret remains in any existing forks or
clones of the repository.

## Pinning to specific analyzer version

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
  - template: Security/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRETS_ANALYZER_VERSION: "4.5"
```

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

You can use passthroughs to override the default Secret Detection ruleset. The
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
  # add regexes to the regex table
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
[passthroughs section on the SAST customize rulesets](../sast/customize_rulesets.md#the-analyzerpassthrough-section)
page.

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

## Warnings for potential leaks in text content

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368434) in GitLab 15.11.

When you create an issue, propose a merge request, or write a comment, you might accidentally post a sensitive value.
For example, you might paste in the details of an API request or an environment variable that contains an authentication token.

GitLab checks if the text of your issue description, merge request description, comment, or reply contains a sensitive token.
If a token is found, a warning message is displayed. You can then edit your message before posting it.
This check happens in your browser before the message is sent to the server.
The check is always on; you don't have to set it up.

Your text is checked for the following secret types:

- GitLab [personal access tokens](../../../security/token_overview.md#personal-access-tokens)
- GitLab [feed tokens](../../../security/token_overview.md#feed-token)

This feature is separate from Secret Detection scanning, which checks your Git repository for leaked secrets.
[Issue 405147](https://gitlab.com/gitlab-org/gitlab/-/issues/405147) tracks efforts to align these two types of protection.

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

For information on this, see the [general Application Security troubleshooting section](../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload).

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

### `exec /bin/sh: exec format error` message in job log

The GitLab Secret Detection analyzer [only supports](#enable-secret-detection) running on the `amd64` CPU architecture.
This message indicates that the job is being run on a different architecture, such as `arm`.
