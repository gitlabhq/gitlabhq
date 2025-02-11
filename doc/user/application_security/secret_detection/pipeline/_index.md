---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---
<!-- markdownlint-disable MD025 -->

# Pipeline secret detection

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Pipeline secret detection scans files after they are committed to a Git repository and pushed to GitLab.

After you [enable pipeline secret detection](#enable-the-analyzer), scans run in a CI/CD job named `secret_detection`.
You can run scans and view [pipeline secret detection JSON report artifacts](../../../../ci/yaml/artifacts_reports.md#artifactsreportssecret_detection) in any GitLab tier.

With GitLab Ultimate, pipeline secret detection results are also processed so you can:

- See them in the [merge request widget](../../detect/security_scan_results.md#merge-request), [pipeline security report](../../vulnerability_report/pipeline.md), and [vulnerability report](../../vulnerability_report/_index.md) UIs.
- Use them in approval workflows.
- Review them in the security dashboard.
- [Automatically respond](../automatic_response.md) to leaks in public repositories.
- Enforce consistent secret detection rules across projects using [security policies](../../policies/_index.md).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> For an interactive reading and how-to demo of this pipeline secret detection documentation see:

- [How to enable secret detection in GitLab Application Security Part 1/2](https://youtu.be/dbMxeO6nJCE?feature=shared)
- [How to enable secret detection in GitLab Application Security Part 2/2](https://youtu.be/VL-_hdiTazo?feature=shared)

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> For other interactive reading and how-to demos, see the [Get Started With GitLab Application Security Playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9).

## Detected secrets

Pipeline secret detection scans the repository's content for specific patterns. Each pattern matches
a specific type of secret and is specified in a rule by using a TOML syntax. The default set of
rules is maintained by GitLab. In the Ultimate tier, you can customize the default ruleset to suit
your needs. For details, see [Customize analyzer rulesets](#customize-analyzer-rulesets). To confirm
which secrets are detected by pipeline secret detection, see
[Detected secrets](../detected_secrets.md). To provide reliable, high-confidence results, pipeline
secret detection only looks for passwords or other unstructured secrets in specific contexts like
URLs.

When a secret is detected a vulnerability is created for it. The vulnerability remains as "Still
detected" even if the secret is removed from the scanned file and pipeline secret detection has been
run again. This is because the secret remains in the Git repository's history. To remove a secret
from the Git repository's history, see
[Redact text from repository](../../../project/merge_requests/revert_changes.md#redact-text-from-repository).

## Coverage

Pipeline secret detection scans different aspects of your code, depending on the situation. For all methods
except "Default branch", pipeline secret detection scans commits, not the working tree. For example,
pipeline secret detection can detect if a secret was added in one commit and removed in a later commit.

- Historical scan

  If the `SECRET_DETECTION_HISTORIC_SCAN` variable is set, the content of all
  [branches](../../../project/repository/branches/_index.md) is scanned. Before scanning the
  repository's content, pipeline secret detection runs the command `git fetch --all` to fetch the content of all
  branches.

- Commit range

  If the `SECRET_DETECTION_LOG_OPTIONS` variable is set, the secrets analyzer fetches the entire
  history of the branch or reference the pipeline is being run for. Pipeline secret detection then runs,
  scanning the commit range specified.

- Default branch

  When pipeline secret detection is run on the default branch, the Git repository is treated as a plain
  folder. Only the contents of the repository at the current HEAD are scanned. Commit history is not scanned.

- Push event

  On a push event, pipeline secret detection determines what commit range to scan, given the information
  available in the runner. To determine the commit range, the variables `CI_COMMIT_SHA` and
  `CI_COMMIT_BEFORE_SHA` are important.

  - `CI_COMMIT_SHA` is the commit at HEAD for a given branch. This variable is always set for push events.
  - `CI_COMMIT_BEFORE_SHA` is set in most cases. However, it is not set for the first push event on
    a new branch, nor for merge pipelines. Because of this, pipeline secret detection can't be guaranteed
    when multiple commits are committed to a new branch.

- Merge request

  In a merge request, pipeline secret detection scans every commit made on the source branch. To use this
  feature, you must use the [`latest` pipeline secret detection template](../../detect/roll_out_security_scanning.md#use-security-scanning-tools-with-merge-request-pipelines), as it supports
  [merge request pipelines](../../../../ci/pipelines/merge_request_pipelines.md). Pipeline secret detection's
  results are only available after the pipeline is completed.

## Full history pipeline secret detection

By default, pipeline secret detection scans only the current state of the Git repository. Any secrets
contained in the repository's history are not detected. To address this, pipeline secret detection can
scan the Git repository's full history.

You should do a full history scan only once, after enabling pipeline secret detection. A full history
can take a long time, especially for larger repositories with lengthy Git histories. After
completing an initial full history scan, use only standard pipeline secret detection as part of your
pipeline.

## Advanced vulnerability tracking

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/434096) in GitLab 17.0.

When developers make changes to a file with identified secrets, it's likely that the positions of these secrets will also change. Pipeline secret detection may have already flagged these secrets as vulnerabilities, tracked in the [Vulnerability Report](../../vulnerability_report/_index.md). These vulnerabilities are associated with specific secrets for easy identification and action. However, if the detected secrets aren't accurately tracked as they shift, managing vulnerabilities becomes challenging, potentially resulting in duplicate vulnerability reports.

Pipeline secret detection uses an advanced vulnerability tracking algorithm to more accurately identify when the same secret has moved within a file due to refactoring or unrelated changes.

For more information, see the confidential project `https://gitlab.com/gitlab-org/security-products/post-analyzers/tracking-calculator`. The content of this project is available only to GitLab team members.

### Unsupported workflows

- The algorithm does not support the workflow where the existing finding lacks a tracking signature and does not share the same location as the newly detected finding.
- For some rule types, such as cryptographic keys, pipeline secret detection identifies leaks by matching prefix of the secret rather than the entire secret value. In this scenario, the algorithm consolidates different secrets of the same rule type in a file into a single finding, rather than treating each distinct secret as a separate finding. For example, the [SSH Private Key rule type](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/d2919f65f1d8001755015b5d790af620676b97ea/gitleaks.toml#L138) matches only the `-----BEGIN OPENSSH PRIVATE KEY-----` prefix of a value to confirm the presence of a SSH private key. If there are two distinct SSH Private Keys within the same file, the algorithm considers both values as identical and reports only one finding instead of two.
- The algorithm's scope is limited to a per-file basis, meaning that the same secret appearing in two different files is treated as two distinct findings.

## Output

Pipeline secret detection outputs the file `gl-secret-detection-report.json` as a job artifact. The file contains detected secrets. You can [download](../../../../ci/jobs/job_artifacts.md#download-job-artifacts) the file for processing outside GitLab.

For more information, see:

- [Report file schema](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/secret-detection-report-format.json)
- [Example report file](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/qa/expect/secrets/gl-secret-detection-report.json)

## Configuration

### Requirements

Prerequisites:

- Linux-based GitLab Runner with the [`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
  [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor. If you're using
  hosted runners for GitLab.com, this is enabled by default.
  - Windows Runners are not supported.
  - CPU architectures other than amd64 are not supported.
- GitLab CI/CD configuration (`.gitlab-ci.yml`) must include the `test` stage.

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/).

| Capability                                                                                           | In Free & Premium      | In Ultimate            |
|:-----------------------------------------------------------------------------------------------------|:-----------------------|:-----------------------|
| [Enable the analyzer](#enable-the-analyzer)                                                          | **{check-circle}** Yes | **{check-circle}** Yes |
| [Customize analyzer settings](#customize-analyzer-settings)                                          | **{check-circle}** Yes | **{check-circle}** Yes |
| Download [output](#output)                                                                           | **{check-circle}** Yes | **{check-circle}** Yes |
| See new findings in the merge request widget                                                         | **{dotted-circle}** No | **{check-circle}** Yes |
| View identified secrets in the pipelines' **Security** tab                                           | **{dotted-circle}** No | **{check-circle}** Yes |
| [Manage vulnerabilities](../../vulnerability_report/_index.md)                                        | **{dotted-circle}** No | **{check-circle}** Yes |
| [Access the Security Dashboard](../../security_dashboard/_index.md)                                   | **{dotted-circle}** No | **{check-circle}** Yes |
| [Customize analyzer rulesets](#customize-analyzer-rulesets)                                          | **{dotted-circle}** No | **{check-circle}** Yes |
| [Enable security policies](../../policies/_index.md)                                                  | **{dotted-circle}** No | **{check-circle}** Yes |

### Enable the analyzer

To enable pipeline secret detection, either:

- Enable [Auto DevOps](../../../../topics/autodevops/_index.md), which includes [Auto Secret Detection](../../../../topics/autodevops/stages.md#auto-secret-detection).

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

Pipelines now include a pipeline secret detection job.

#### Use an automatically configured merge request

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4496) in GitLab 13.11, deployed behind a feature flag, enabled by default.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/329886) in GitLab 14.1.

This method automatically prepares a merge request, with the pipeline secret detection template included in
the `.gitlab-ci.yml` file. You then merge the merge request to enable pipeline secret detection.

NOTE:
This method works best with no existing `.gitlab-ci.yml` file, or with a minimal configuration
file. If you have a complex GitLab configuration file it may not be parsed successfully, and an
error may occur. In that case, use the [manual](#edit-the-gitlab-ciyml-file-manually) method instead.

To enable pipeline secret detection:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Pipeline secret detection** row, select **Configure with a merge request**.
1. Optional. Complete the fields.
1. Select **Create merge request**.
1. Review and merge the merge request.

Pipelines now include a pipeline secret detection job.

### Customize analyzer settings

The pipeline secret detection scan settings can be changed through [CI/CD variables](#available-cicd-variables)
by using the [`variables`](../../../../ci/yaml/_index.md#variables) parameter in `.gitlab-ci.yml`.

WARNING:
All configuration of GitLab security scanning tools should be tested in a merge request before
merging these changes to the default branch. Failure to do so can give unexpected results,
including a large number of false positives.

#### Add new patterns

To search for other types of secrets in your repositories, you can [customize analyzer rulesets](#customize-analyzer-rulesets).

To propose a new detection rule for all users of pipeline secret detection, [see our single source of truth for our rules](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/blob/main/README.md) and follow the guidance to create a merge request.

If you operate a cloud or SaaS product and you're interested in partnering with GitLab to better protect your users, learn more about our [partner program for leaked credential notifications](../automatic_response.md#partner-program-for-leaked-credential-notifications).

#### Pin to specific analyzer version

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

#### Enable full history scan

To enable full history scan, set the variable `SECRET_DETECTION_HISTORIC_SCAN` to `true` in your `.gitlab-ci.yml` file.

#### Run jobs in merge request pipelines

See [Use security scanning tools with merge request pipelines](../../detect/roll_out_security_scanning.md#use-security-scanning-tools-with-merge-request-pipelines).

#### Override the analyzer jobs

To override a job definition, (for example, change properties like `variables` or `dependencies`),
declare a job with the same name as the `secret_detection` job to override. Place this new job after
the template inclusion and specify any additional keys under it.

In the following example _extract_ of a `.gitlab-ci.yml` file:

- The `Jobs/Secret-Detection` CI template is [included](../../../../ci/yaml/_index.md#include).
- In the `secret_detection` job, the CI/CD variable `SECRET_DETECTION_HISTORIC_SCAN` is set to
  `true`. Because the template is evaluated before the pipeline configuration, the last mention of
  the variable takes precedence, so an historic scan is performed.

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_HISTORIC_SCAN: "true"
```

### Customize analyzer rulesets

DETAILS:
**Tier:** Ultimate

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/211387) in GitLab 13.5.
> - Expanded to include additional passthrough types of `file` and `raw` in GitLab 14.6.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/235359) support for overriding rules in GitLab 14.8.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/336395) support for passthrough chains and included additional passthrough types of `git` and `url` in GitLab 17.2.

You can customize the behavior of pipeline secret detection by [creating a ruleset configuration file](#create-a-ruleset-configuration-file),
either in the repository being scanned or a remote repository. Customization enables you to modify, replace, or extend the default ruleset.

There are multiple kinds of customizations available:

- Modify the behavior of **rules predefined in the default ruleset**. This includes:
  - [Override a rule from the default ruleset](#override-a-rule).
  - [Disable a rule from the default ruleset](#disable-a-rule).
  - [Disable or override a rule with a remote ruleset](#with-a-remote-ruleset).
- Replace the default ruleset with a custom ruleset using passthroughs. This includes:
  - [Use configuration from an inline ruleset](#with-an-inline-ruleset).
  - [Use configuration from a local ruleset](#with-a-local-ruleset).
  - [Use configuration from a remote ruleset](#with-a-remote-ruleset-1).
  - [Use configuration from a private remote ruleset](#with-a-private-remote-ruleset)
- Extend the behavior of the default ruleset using passthroughs. This includes:
  - [Use configuration from a local ruleset](#with-a-local-ruleset-1).
  - [Use configuration from a remote ruleset](#with-a-remote-ruleset-2).
- Ignore secrets and paths using Gitleaks-native functionality. This includes:
  - Use [`Gitleaks' [allowlist] directive`](https://github.com/gitleaks/gitleaks#configuration) to [ignore patterns and paths](#ignore-patterns-and-paths).
  - Use `gitleaks:allow` comment to [ignore secrets inline](#ignore-secrets-inline).

#### Create a ruleset configuration file

To create a ruleset configuration file:

1. Create a `.gitlab` directory at the root of your project, if one doesn’t already exist.
1. Create a file named `secret-detection-ruleset.toml` in the `.gitlab` directory.

#### Modify rules from the default ruleset

You can modify rules predefined in the [default ruleset](../detected_secrets.md).

Modifying rules can help you adapt pipeline secret detection to an existing workflow or tool. For example you may want to override the severity of a detected secret or disable a rule from being detected at all.

You can also use a ruleset configuration file stored remotely (that is, a remote Git repository or website) to modify predefined rules.

##### Disable a rule

> - Ability to disable a rule with a remote ruleset was [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/425251) in GitLab 16.0 and later.

You can disable rules that you don't want active. To disable rules from the analyzer default ruleset:

1. [Create a ruleset configuration file](#create-a-ruleset-configuration-file), if one doesn't exist already.
1. Set the `disabled` flag to `true` in the context of a [`ruleset` section](../pipeline/custom_rulesets_schema.md#the-secretsruleset-section).
1. In one or more `ruleset.identifier` subsections, list the rules to disable. Every
   [`ruleset.identifier` section](../pipeline/custom_rulesets_schema.md#the-secretsrulesetidentifier-section) has:
   - A `type` field for the predefined rule identifier.
   - A `value` field for the rule name.

In the following example `secret-detection-ruleset.toml` file, the disabled rules are matched by the `type` and `value` of identifiers:

```toml
[secrets]
  [[secrets.ruleset]]
    disable = true
    [secrets.ruleset.identifier]
      type  = "gitleaks_rule_id"
      value = "RSA private key"
```

##### Override a rule

> - Ability to override a rule with a remote ruleset was [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/425251) in GitLab 16.0 and later.

If there are specific rules to customize, you can override them. For example, you may increase the severity of a specific type of secret because leaking it would have a higher impact on your workflow.

To override rules from the analyzer default ruleset:

1. [Create a ruleset configuration file](#create-a-ruleset-configuration-file), if one doesn't exist already.
1. In one or more `ruleset.identifier` subsections, list the rules to override. Every
   [`ruleset.identifier` section](../pipeline/custom_rulesets_schema.md#the-secretsrulesetidentifier-section) has:
   - A `type` field for the predefined rule identifier.
   - A `value` field for the rule name.
1. In the [`ruleset.override` context](../pipeline/custom_rulesets_schema.md#the-secretsrulesetoverride-section) of a [`ruleset` section](../pipeline/custom_rulesets_schema.md#the-secretsruleset-section), provide the keys to override. Any combination of keys can be overridden. Valid keys are:
   - `description`
   - `message`
   - `name`
   - `severity` (valid options are: `Critical`, `High`, `Medium`, `Low`, `Unknown`, `Info`)

In the following `secret-detection-ruleset.toml` file, rules are matched by the `type` and `value` of identifiers and then overridden:

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.identifier]
      type  = "gitleaks_rule_id"
      value = "RSA private key"
    [secrets.ruleset.override]
      description = "OVERRIDDEN description"
      message     = "OVERRIDDEN message"
      name        = "OVERRIDDEN name"
      severity    = "Info"
```

##### With a remote ruleset

A **remote ruleset is a configuration file stored outside the current repository**. It can be used to modify rules across multiple projects.

To modify a predefined rule with a remote ruleset, you can use the `SECRET_DETECTION_RULESET_GIT_REFERENCE` [CI/CD variable](../../../../ci/variables/_index.md):

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

variables:
  SECRET_DETECTION_RULESET_GIT_REFERENCE: "gitlab.com/example-group/remote-ruleset-project"
```

Pipeline secret detection assumes the configuration is defined in `.gitlab/secret-detection-ruleset.toml` file in the repository referenced by the CI variable where the remote ruleset is stored. If that file doesn't exist, please make sure to [create one](#create-a-ruleset-configuration-file) and follow the steps to [override](#override-a-rule) or [disable](#disable-a-rule) a predefined rule as outlined above.

NOTE:
A local `.gitlab/secret-detection-ruleset.toml` file in the project takes precedence over `SECRET_DETECTION_RULESET_GIT_REFERENCE` by default because `SECURE_ENABLE_LOCAL_CONFIGURATION` is set to `true`.
If you set `SECURE_ENABLE_LOCAL_CONFIGURATION` to `false`, the local file is ignored and the default configuration or `SECRET_DETECTION_RULESET_GIT_REFERENCE` (if set) is used.

The `SECRET_DETECTION_RULESET_GIT_REFERENCE` variable uses a format similar to [Git URLs](https://git-scm.com/docs/git-clone#_git_urls) for specifying a URI, optional authentication, and optional Git SHA. The variable uses the following format:

```plaintext
<AUTH_USER>:<AUTH_PASSWORD>@<PROJECT_PATH>@<GIT_SHA>
```

If the configuration file is stored in a private project that requires authentication, you may use a [Group Access Token](../../../group/settings/group_access_tokens.md) securely stored in a CI variable to load the remote ruleset:

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

variables:
  SECRET_DETECTION_RULESET_GIT_REFERENCE: "group_2504721_bot_7c9311ffb83f2850e794d478ccee36f5:$GROUP_ACCESS_TOKEN@gitlab.com/example-group/remote-ruleset-project"
```

The group access token must have the `read_repository` scope and at least the Reporter role. For details, see [Repository permissions](../../../permissions.md#repository).

See [bot users for groups](../../../group/settings/group_access_tokens.md#bot-users-for-groups) to learn how to find the username associated with a group access token.

#### Replace the default ruleset

You can replace the default ruleset configuration using a number of [customizations](../pipeline/custom_rulesets_schema.md). Those can be combined using [passthroughs](../pipeline/custom_rulesets_schema.md#passthrough-types) into a single configuration.

Using passthroughs, you can:

- Chain up to [20 passthroughs](../pipeline/custom_rulesets_schema.md#the-secretspassthrough-section) into a single configuration to replace or extend predefined rules.
- Include [environment variables in passthroughs](../pipeline/custom_rulesets_schema.md#interpolate).
- Set a [timeout](../pipeline/custom_rulesets_schema.md#the-secrets-configuration-section) for evaluating passthroughs.
- [Validate](../pipeline/custom_rulesets_schema.md#the-secrets-configuration-section) TOML syntax used in each defined passthrough.

##### With an inline ruleset

You can use [`raw` passthrough](../pipeline/custom_rulesets_schema.md#passthrough-types) to replace default ruleset with configuration provided inline.

To do so, add the following in the `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository, and adjust the rule defined under `[[rules]]` as appropriate:

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "raw"
    target = "gitleaks.toml"
    value  = """
title = "replace default ruleset with a raw passthrough"

[[rules]]
description = "Test for Raw Custom Rulesets"
regex = '''Custom Raw Ruleset T[est]{3}'''
"""
```

The above example replaces the default ruleset with a rule that checks for the regex defined - `Custom Raw Ruleset T` with a suffix of 3 characters from either one of `e`, `s`, or `t` letters.

For more information on the passthrough syntax to use, see [Schema](../pipeline/custom_rulesets_schema.md#schema).

##### With a local ruleset

You can use [`file` passthrough](../pipeline/custom_rulesets_schema.md#passthrough-types) to replace the default ruleset with another file committed to the current repository.

To do so, add the following in the `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository and adjust the `value` as appropriate to point to the path of the file with the local ruleset configuration:

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "config/gitleaks.toml"
```

This would replace the default ruleset with the configuration defined in `config/gitleaks.toml` file.

For more information on the passthrough syntax to use, see [Schema](../pipeline/custom_rulesets_schema.md#schema).

##### With a remote ruleset

You can replace the default ruleset with configuration defined in a remote Git repository or a file stored somewhere online using the `git` and `url` passthroughs, respectively.

A remote ruleset can be used across multiple projects. For example, you may want to apply the same
ruleset to a number of projects in one of your namespaces, in such case, you may use either type of
passthrough to load up that remote ruleset and have it used by multiple projects. It also enables
centralized management of a ruleset, with only authorized people able to edit.

To use `git` passthrough, add the following to the `.gitlab/secret-detection-ruleset.toml` configuration file stored in a repository and adjust the `value` to point to the address of the Git repository:

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

In this configuration the analyzer loads the ruleset from the `gitleaks.toml` file inside the `config` directory in the `main` branch of the repository stored at `user_group/central_repository_with_shared_ruleset`. You can then proceed to include the same configuration in projects other than `user_group/basic_repository`.

Alternatively, you may use the `url` passthrough to replace the default ruleset with a remote ruleset configuration.

To use the `url` passthrough, add the following to the `.gitlab/secret-detection-ruleset.toml` configuration file stored in a repository and adjust the `value` to point to the address of the remote file:

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "url"
    target = "gitleaks.toml"
    value  = "https://example.com/gitleaks.toml"
```

In this configuration the analyzer loads the ruleset configuration from `gitleaks.toml` file stored at the address provided.

For more information on the passthrough syntax to use, see [Schema](../pipeline/custom_rulesets_schema.md#schema).

##### With a private remote ruleset

If a ruleset configuration is stored in a private repository you must provide the credentials to access the repository by using the passthrough's [`auth` setting](../pipeline/custom_rulesets_schema.md#the-secretspassthrough-section).

NOTE:
The `auth` setting only works with `git` passthrough.

To use a remote ruleset stored in a private repository, add the following to the `.gitlab/secret-detection-ruleset.toml` configuration file stored in a repository, adjust the `value` to point to the address of the Git repository, and update `auth` to use the appropriate credentials:

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    auth   = "USERNAME:PASSWORD" # replace USERNAME and PASSWORD as appropriate
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

WARNING:
Beware of leaking credentials when using this feature. Check [this section](../pipeline/custom_rulesets_schema.md#interpolate) for an example on how to use environment variables to minimize the risk.

For more information on the passthrough syntax to use, see [Schema](../pipeline/custom_rulesets_schema.md#schema).

#### Extend the default ruleset

You can also extend the [default ruleset](../detected_secrets.md) configuration with additional rules as appropriate. This can be helpful when you would still like to benefit from the high-confidence predefined rules maintained by GitLab in the default ruleset, but also want to add rules for types of secrets that may be used in your own projects and namespaces.

##### With a local ruleset

You can use a `file` passthrough to extend the default ruleset to add additional rules.

Add the following to the `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository, and adjust the `value` as appropriate to point to the path of the extended configuration file:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

The extended configuration stored in `extended-gitleaks-config.toml` is included in the configuration used by the analyzer
in the CI/CD pipeline.

In the example below, we add a couple of new `[[rules]]` sections that define a number of regular expressions to be detected:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  description = "Example Service API Key"
  regex = '''example_api_key'''

[[rules]]
  description = "Example Service API Secret"
  regex = '''example_api_secret'''
```

With this ruleset configuration the analyzer detects any strings matching with those two defined regex patterns.

For more information on the passthrough syntax to use, see [Schema](../pipeline/custom_rulesets_schema.md#schema).

##### With a remote ruleset

Similar to how you can replace the default ruleset with a remote ruleset, you can also extend the default ruleset with configuration stored in a remote Git repository or file stored external to the repository in which you have the `.gitlab/secret-detection-ruleset.toml` configuration file.

This can be achieved by using either of the `git` or `url` passthroughs as discussed previously.

To do that with a `git` passthrough, add the following to `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository, and adjust the `value`, `ref`, and `subdir` as appropriate to point to the path of the extended configuration file:

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

Pipeline secret detection assumes the remote ruleset configuration file is called `gitleaks.toml`, and is stored in `config` directory on the `main` branch of the referenced repository.

To extend the default ruleset, the `gitleaks.toml` file should use `[extend]` directive similar to the example above:

```toml
# https://gitlab.com/user_group/central_repository_with_shared_ruleset/-/raw/main/config/gitleaks.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  description = "Example Service API Key"
  regex = '''example_api_key'''

[[rules]]
  description = "Example Service API Secret"
  regex = '''example_api_secret'''
```

To use a `url` passthrough, add the following to `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository, and adjust the `value` as appropriate to point to the path of the extended configuration file

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "url"
    target = "gitleaks.toml"
    value  = "https://example.com/gitleaks.toml"
```

For more information on the passthrough syntax to use, see [Schema](../pipeline/custom_rulesets_schema.md#schema).

#### Ignore patterns and paths

There may be situations in which you need to ignore a certain pattern or path from being detected by pipeline secret detection. For example, you may have a file including fake secrets to be used in a test suite.

In that case, you can utilize [Gitleaks' native `[allowlist]`](https://github.com/gitleaks/gitleaks#configuration) directive to ignore specific patterns or paths.

NOTE:
This feature works regardless of whether you're using a local or a remote ruleset configuration file. The examples below utilizes a local ruleset using `file` passthrough though.

To ignore a pattern, add the following to the `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository, and adjust the `value` as appropriate to point to the path of the extended configuration file:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

The extended configuration stored in `extended-gitleaks-config.toml` will be included in the configuration used by the analyzer.

In the example below, we add an `[allowlist]` directive that defines a regex that matches the secret to be ignored ("allowed"):

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[allowlist]
  description = "allowlist of patterns to ignore in detection"
  regexTarget = "match"
  regexes = [
    '''glpat-[0-9a-zA-Z_\\-]{20}'''
  ]
```

This ignores any string matching `glpat-` with a suffix of 20 characters of digits and letters.

Similarly, you can exclude specific paths from being scanned. In the example below, we define an array of paths to ignore under the `[allowlist]` directive. A path could either be a regular expression, or a specific file path:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[allowlist]
  description = "allowlist of patterns to ignore in detection"
  paths = [
    '''/gitleaks.toml''',
    '''(.*?)(jpg|gif|doc|pdf|bin|svg|socket)'''
  ]
```

This ignores any secrets detected in either `/gitleaks.toml` file or any file ending with one of the specified extensions.

For more information on the passthrough syntax to use, see [Schema](../pipeline/custom_rulesets_schema.md#schema).

#### Ignore secrets inline

In some instances, you might want to ignore a secret inline. For example, you may have a fake secret in an example or a test suite. In these instances, you will want to ignore the secret instead of having it reported as a vulnerability.

To ignore a secret, add `gitleaks:allow` as a comment to the line that contains the secret.

For example:

```ruby
"A personal token for GitLab will look like glpat-JUST20LETTERSANDNUMB"  # gitleaks:allow
```

#### Detecting complex strings

The [default ruleset](#detected-secrets) provides patterns to detect structured strings with a low rate of false positives.
However, you might want to detect more complex strings like passwords. Because [Gitleaks doesn't support lookahead or lookbehind](https://github.com/google/re2/issues/411),
writing a high-confidence, general rule to detect unstructured strings is not possible.

Although you can't detect every complex string, you can extend your ruleset to meet specific use cases.

For example, this rule modifies the [`generic-api-key` rule](https://github.com/gitleaks/gitleaks/blob/4e43d1109303568509596ef5ef576fbdc0509891/config/gitleaks.toml#L507-L514) from the Gitleaks default ruleset:

```regex
(?i)(?:pwd|passwd|password)(?:[0-9a-z\-_\t .]{0,20})(?:[\s|']|[\s|"]){0,3}(?:=|>|=:|:{1,3}=|\|\|:|<=|=>|:|\?=)(?:'|\"|\s|=|\x60){0,5}([0-9a-z\-_.=\S_]{3,50})(?:['|\"|\n|\r|\s|\x60|;]|$)
```

This regular expression matches:

1. A case-insensitive identifier that starts with `pwd`, or `passwd` or `password`. You can adjust this with other variations like `secret` or `key`.
1. A suffix that follows the identifier. The suffix is a combination of digits, letters, and symbols, and is between zero and 23 characters long.
1. Commonly used assignment operators, like `=`, `:=`, `:`, or `=>`.
1. A secret prefix, often used as a boundary to help with detecting the secret.
1. A string of digits, letters, and symbols, which is between three and 50 characters long. This is the secret itself. If you expect longer strings, you can adjust the length.
1. A secret suffix, often used as a boundary. This matches common endings like ticks, line breaks, and new lines.

Here are example strings which are matched by this regular expression:

```plaintext
pwd = password1234
passwd = 'p@ssW0rd1234'
password = thisismyverylongpassword
password => mypassword
password := mypassword
password: password1234
"password" = "p%ssward1234"
'password': 'p@ssW0rd1234'
```

To use this regex, extend your ruleset with one of the methods documented on this page.

For example, imagine you wish to extend the default ruleset [with a local ruleset](#with-a-local-ruleset-1) that includes this rule.

Add the following to a `.gitlab/secret-detection-ruleset.toml` configuration file stored in the same repository. Adjust the `value` to point to the path of the extended configuration file:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

In `extended-gitleaks-config.toml` file, add a new `[[rules]]` section with the regular expression you want to use:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  description = "Generic Password Rule"
  id = "generic-password"
  regex = '''(?i)(?:pwd|passwd|password)(?:[0-9a-z\-_\t .]{0,20})(?:[\s|']|[\s|"]){0,3}(?:=|>|=:|:{1,3}=|\|\|:|<=|=>|:|\?=)(?:'|\"|\s|=|\x60){0,5}([0-9a-z\-_.=\S_]{3,50})(?:['|\"|\n|\r|\s|\x60|;]|$)'''
  entropy = 3.5
  keywords = ["pwd", "passwd", "password"]
```

NOTE:
This example configuration is provided only for convenience, and might not work
for all use cases. If you configure your ruleset to detect complex strings, you might
create a large number of false positives, or fail to capture certain patterns.

### Available CI/CD variables

Pipeline secret detection can be customized by defining available CI/CD variables:

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
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

An offline environment has limited, restricted, or intermittent access to external resources through
the internet. For instances in such an environment, pipeline secret detection requires
some configuration changes. The instructions in this section must be completed together with the
instructions detailed in [offline environments](../../offline_deployments/_index.md).

#### Configure GitLab Runner

By default, a runner tries to pull Docker images from the GitLab container registry even if a local
copy is available. You should use this default setting, to ensure Docker images remain current.
However, if no network connectivity is available, you must change the default GitLab Runner
`pull_policy` variable.

Configure the GitLab Runner CI/CD variable `pull_policy` to
[`if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy).

#### Use local pipeline secret detection analyzer image

Use a local pipeline secret detection analyzer image if you want to obtain the image from a local Docker
registry instead of the GitLab container registry.

Prerequisites:

- Importing Docker images into a local offline Docker registry depends on your
  network security policy. Consult your IT staff to find an accepted and approved process
  to import or temporarily access external resources.

1. Import the default pipeline secret detection analyzer image from `registry.gitlab.com` into your
   [local Docker container registry](../../../packages/container_registry/_index.md):

   ```plaintext
   registry.gitlab.com/security-products/secrets:6
   ```

   The pipeline secret detection analyzer's image is [periodically updated](../../_index.md#vulnerability-scanner-maintenance)
   so you should periodically update the local copy.

1. Set the CI/CD variable `SECURE_ANALYZERS_PREFIX` to the local Docker container registry.

   ```yaml
   include:
     - template: Jobs/Secret-Detection.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
   ```

The pipeline secret detection job should now use the local copy of the analyzer Docker image,
without requiring internet access.

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

### Demos

There are [demonstration projects](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection) that illustrate some of these configuration options.

Below is a table with the demonstration projects and their associated workflows:

| Action/Workflow         | Applies to/via | With inline or local ruleset | With remote ruleset |
| ----------------------- | -------------- | ------------------ | ------------------- |
| Disable a rule          | Predefined rules | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/disable-rule-project/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/disable-rule-project) | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/disable-rule-ruleset) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/disable-rule-project) |
| Override a rule         | Predefined rules | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/override-rule-project/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/override-rule-project) | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/override-rule-ruleset) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/override-rule-project) |
| Replace default ruleset | File Passthrough | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/file-passthrough/-/blob/main/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/file-passthrough) | Not applicable |
| Replace default ruleset | Raw Passthrough | [Inline Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/raw-passthrough/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/raw-passthrough) | Not applicable |
| Replace default ruleset | Git Passthrough | Not applicable | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-replace/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/git-passthrough) |
| Replace default ruleset | URL Passthrough | Not applicable | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-replace/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/url-passthrough) |
| Extend default ruleset  | File Passthrough | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/file-passthrough) | Not applicable |
| Extend default ruleset  | Git Passthrough | Not applicable | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-extend/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/git-passthrough) |
| Extend default ruleset  | URL Passthrough | Not applicable | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-extend/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/url-passthrough) |
| Ignore paths            | File Passthrough | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/file-passthrough) | Not applicable |
| Ignore paths            | Git Passthrough | Not applicable | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-paths/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/git-passthrough) |
| Ignore paths            | URL Passthrough | Not applicable | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-paths/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/url-passthrough) |
| Ignore patterns         | File Passthrough | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/file-passthrough) | Not applicable |
| Ignore patterns         | Git Passthrough | Not applicable | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-patterns/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/git-passthrough) |
| Ignore patterns         | URL Passthrough | Not applicable | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-patterns/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/url-passthrough) |
| Ignore values           | File Passthrough | [Local Ruleset](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/file-passthrough) | Not applicable |
| Ignore values           | Git Passthrough | Not applicable | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-values/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/git-passthrough) |
| Ignore values           | URL Passthrough | Not applicable | [Remote Ruleset](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-values/config/gitleaks.toml) / [Project](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/url-passthrough) |

There are also some video demonstrations walking through setting up remote rulesets:

- [Secret detection with local and remote ruleset](https://youtu.be/rsN1iDug5GU)

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

The pipeline secret detection analyzer relies on generating patches between commits to scan content for
secrets. If the number of commits in a merge request is greater than the value of the
[`GIT_DEPTH` CI/CD variable](../../../../ci/runners/configure_runners.md#shallow-cloning), Secret
Detection [fails to detect secrets](#error-couldnt-run-the-gitleaks-command-exit-status-2).

For example, you could have a pipeline triggered from a merge request containing 60 commits and the
`GIT_DEPTH` variable set to less than 60. In that case the pipeline secret detection job fails because the
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
to a higher value. To apply this only to the pipeline secret detection job, the following can be added to
your `.gitlab-ci.yml` file:

```yaml
secret_detection:
  variables:
    GIT_DEPTH: 100
```

#### Error: `ERR fatal: ambiguous argument`

Pipeline secret detection can fail with the message `ERR fatal: ambiguous argument` error if your
repository's default branch is unrelated to the branch the job was triggered for. See issue
[!352014](https://gitlab.com/gitlab-org/gitlab/-/issues/352014) for more details.

To resolve the issue, make sure to correctly [set your default branch](../../../project/repository/branches/default.md#change-the-default-branch-name-for-a-project)
on your repository. You should set it to a branch that has related history with the branch you run
the `secret-detection` job on.

#### `exec /bin/sh: exec format error` message in job log

The GitLab pipeline secret detection analyzer [only supports](#enable-the-analyzer) running on the `amd64` CPU architecture.
This message indicates that the job is being run on a different architecture, such as `arm`.

#### Error: `fatal: detected dubious ownership in repository at '/builds/<project dir>'`

Secret detection might fail with an exit status of 128. This can be caused by a change to the user on the Docker image.

For example:

```shell
$ /analyzer run
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ GitLab secrets analyzer v6.0.1
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Detecting project
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Analyzer will attempt to analyze all projects in the repository
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Loading ruleset for /builds....
[WARN] [secrets] [2024-06-06T07:28:13Z] ▶ /builds/....secret-detection-ruleset.toml not found, ruleset support will be disabled.
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Running analyzer
[FATA] [secrets] [2024-06-06T07:28:13Z] ▶ get commit count: exit status 128
```

To work around this issue, add a `before_script` with the following:

```yaml
before_script:
    - git config --global --add safe.directory "$CI_PROJECT_DIR"
```

For more information about this issue, see [issue 465974](https://gitlab.com/gitlab-org/gitlab/-/issues/465974).

## Warnings

### Responding to a leaked secret

When a secret is detected, you should rotate it immediately. GitLab attempts to
[automatically revoke](../automatic_response.md) some types of leaked secrets. For those that are not
automatically revoked, you must do so manually.

[Purging a secret from the repository's history](../../../project/repository/repository_size.md#purge-files-from-repository-history)
does not fully address the leak. The original secret remains in any existing forks or
clones of the repository.

<!-- markdownlint-enable MD025 -->
