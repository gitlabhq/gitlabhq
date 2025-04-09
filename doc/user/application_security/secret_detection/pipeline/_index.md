---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pipeline secret detection
---

<!-- markdownlint-disable MD025 -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pipeline secret detection scans files after they are committed to a Git repository and pushed to GitLab.

After you [enable pipeline secret detection](#enable-the-analyzer), scans run in a CI/CD job named `secret_detection`.
You can run scans and view [pipeline secret detection JSON report artifacts](../../../../ci/yaml/artifacts_reports.md#artifactsreportssecret_detection) in any GitLab tier.

With GitLab Ultimate, pipeline secret detection results are also processed so you can:

- See them in the [merge request widget](../../detect/security_scan_results.md#merge-request), [pipeline security report](../../vulnerability_report/pipeline.md), and [vulnerability report](../../vulnerability_report/_index.md).
- Use them in approval workflows.
- Review them in the security dashboard.
- [Automatically respond](../automatic_response.md) to leaks in public repositories.
- Enforce consistent secret detection rules across projects using [security policies](../../policies/_index.md).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> For an interactive reading and how-to demo of this pipeline secret detection documentation see:

- [How to enable secret detection in GitLab Application Security Part 1/2](https://youtu.be/dbMxeO6nJCE?feature=shared)
- [How to enable secret detection in GitLab Application Security Part 2/2](https://youtu.be/VL-_hdiTazo?feature=shared)

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> For other interactive reading and how-to demos, see the [Get Started With GitLab Application Security Playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9).

## Availability

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/).

| Capability                                                                                           | In Free & Premium      | In Ultimate            |
|:-----------------------------------------------------------------------------------------------------|:-----------------------|:-----------------------|
| [Customize analyzer behavior](configure.md#customize-analyzer-behavior)                                          | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes |
| Download [output](#output)                                                                           | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes |
| See new findings in the merge request widget                                                         | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| View identified secrets in the pipelines' **Security** tab                                           | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| [Manage vulnerabilities](../../vulnerability_report/_index.md)                                        | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| [Access the Security Dashboard](../../security_dashboard/_index.md)                                   | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| [Customize analyzer rulesets](configure.md#customize-analyzer-rulesets)                                          | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| [Enable security policies](../../policies/_index.md)                                                  | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |

## Coverage

Pipeline secret detection is optimized to balance coverage and run time.
Only the current state of the repository and future commits are scanned for secrets.
To identify secrets already present in the repository's history, run a historic scan once
after enabling pipeline secret detection. Scan results are available only after the pipeline is completed.

Exactly what is scanned for secrets depends on the type of pipeline,
and whether any additional configuration is set.

By default, when you run a pipeline:

- On a branch:
  - On the **default branch**, the Git working tree is scanned.
    This means the entire repository is scanned as though it were a typical directory.
  - On a **new, non-default branch**, the content of all commits from the most recent commit on the parent branch to the latest commit is scanned.
  - On an **existing, non-default branch**, the content of all commits from the last pushed commit to the latest commit is scanned.
- On a **merge request**, the content of all commits on the branch is scanned. If the analyzer can't access every commit,
  the content of all commits from the parent to the latest commit is scanned. To use merge request pipelines, you must use the
  [`latest` pipeline secret detection template](../../detect/roll_out_security_scanning.md#use-security-scanning-tools-with-merge-request-pipelines).

To override the default behavior, use the [available CI/CD variables](configure.md#available-cicd-variables).

### Historic scan

By default, pipeline secret detection scans only the current state of the Git repository. Any secrets
contained in the repository's history are not detected. Run a historic scan to check for secrets from
all commits and branches in the Git repository.

You should do a historic scan only once, after enabling pipeline secret detection. Historic scans
can take a long time, especially for larger repositories with lengthy Git histories. After
completing an initial historic scan, use only standard pipeline secret detection as part of your
pipeline.

### Advanced vulnerability tracking

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/434096) in GitLab 17.0.

{{< /history >}}

When developers make changes to a file with identified secrets, it's likely that the positions of these secrets will also change. Pipeline secret detection may have already flagged these secrets as vulnerabilities, tracked in the [vulnerability report](../../vulnerability_report/_index.md). These vulnerabilities are associated with specific secrets for easy identification and action. However, if the detected secrets aren't accurately tracked as they shift, managing vulnerabilities becomes challenging, potentially resulting in duplicate vulnerability reports.

Pipeline secret detection uses an advanced vulnerability tracking algorithm to more accurately identify when the same secret has moved within a file due to refactoring or unrelated changes.

For more information, see the confidential project `https://gitlab.com/gitlab-org/security-products/post-analyzers/tracking-calculator`. The content of this project is available only to GitLab team members.

#### Unsupported workflows

- The algorithm does not support the workflow where the existing finding lacks a tracking signature and does not share the same location as the newly detected finding.
- For some rule types, such as cryptographic keys, pipeline secret detection identifies leaks by matching prefix of the secret rather than the entire secret value. In this scenario, the algorithm consolidates different secrets of the same rule type in a file into a single finding, rather than treating each distinct secret as a separate finding. For example, the [SSH Private Key rule type](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/d2919f65f1d8001755015b5d790af620676b97ea/gitleaks.toml#L138) matches only the `-----BEGIN OPENSSH PRIVATE KEY-----` prefix of a value to confirm the presence of a SSH private key. If there are two distinct SSH Private Keys within the same file, the algorithm considers both values as identical and reports only one finding instead of two.
- The algorithm's scope is limited to a per-file basis, meaning that the same secret appearing in two different files is treated as two distinct findings.

### Detected secrets

Pipeline secret detection scans the repository's content for specific patterns. Each pattern matches
a specific type of secret and is specified in a rule by using a TOML syntax. GitLab maintains the default set of rules.

With GitLab Ultimate you can extend these rules to suit your needs. For example, while personal access tokens that use a custom prefix are not detected by default, you can customize the rules to identify these tokens.
For details, see [Customize analyzer rulesets](configure.md#customize-analyzer-rulesets).

To confirm
which secrets are detected by pipeline secret detection, see
[Detected secrets](../detected_secrets.md). To provide reliable, high-confidence results, pipeline
secret detection only looks for passwords or other unstructured secrets in specific contexts like
URLs.

When a secret is detected a vulnerability is created for it. The vulnerability remains as "Still
detected" even if the secret is removed from the scanned file and pipeline secret detection has been
run again. This is because the secret remains in the Git repository's history. To remove a secret
from the Git repository's history, see
[Redact text from repository](../../../project/merge_requests/revert_changes.md#redact-text-from-repository).

## Enable the analyzer

Enable the analyzer to use pipeline secret detection.
After you enable it, you can [customize the analyzer settings](configure.md).

Prerequisites:

- Linux-based GitLab Runner with the [`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
  [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor. If you're using
  hosted runners for GitLab.com, this is enabled by default.
  - Windows Runners are not supported.
  - CPU architectures other than amd64 are not supported.
- GitLab CI/CD configuration (`.gitlab-ci.yml`) must include the `test` stage.

To enable pipeline secret detection, either:

- Enable [Auto DevOps](../../../../topics/autodevops/_index.md), which includes [Auto Secret Detection](../../../../topics/autodevops/stages.md#auto-secret-detection).
- [Edit the `.gitlab-ci.yml` file manually](#edit-the-gitlab-ciyml-file-manually). Use this method
  if your `.gitlab-ci.yml` file is complex.
- [Use an automatically configured merge request](#use-an-automatically-configured-merge-request).

### Edit the `.gitlab-ci.yml` file manually

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

### Use an automatically configured merge request

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4496) in GitLab 13.11, deployed behind a feature flag, enabled by default.
- [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/329886) in GitLab 14.1.

{{< /history >}}

This method automatically prepares a merge request, with the pipeline secret detection template included in
the `.gitlab-ci.yml` file. You then merge the merge request to enable pipeline secret detection.

{{< alert type="note" >}}

This method works best with no existing `.gitlab-ci.yml` file, or with a minimal configuration
file. If you have a complex GitLab configuration file it may not be parsed successfully, and an
error may occur. In that case, use the [manual](#edit-the-gitlab-ciyml-file-manually) method instead.

{{< /alert >}}

To enable pipeline secret detection:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Pipeline secret detection** row, select **Configure with a merge request**.
1. Optional. Complete the fields.
1. Select **Create merge request**.
1. Review and merge the merge request.

Pipelines now include a pipeline secret detection job.

## Output

Pipeline secret detection outputs the file `gl-secret-detection-report.json` as a job artifact. The file contains detected secrets. You can [download](../../../../ci/jobs/job_artifacts.md#download-job-artifacts) the file for processing outside GitLab.

For more information, see:

- [Report file schema](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/secret-detection-report-format.json)
- [Example report file](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/qa/expect/secrets/gl-secret-detection-report.json)

## Remediate a leaked secret

When a secret is detected, you should rotate it immediately. GitLab attempts to
[automatically revoke](../automatic_response.md) some types of leaked secrets. For those that are not
automatically revoked, you must do so manually.

[Purging a secret from the repository's history](../../../project/repository/repository_size.md#purge-files-from-repository-history)
does not fully address the leak. The original secret remains in any existing forks or
clones of the repository.

For instructions on how to respond to a leaked secret, select the vulnerability in the vulnerability report.

## FIPS-enabled images

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6479) in GitLab 14.10.

{{< /history >}}

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

<!-- markdownlint-enable MD025 -->
