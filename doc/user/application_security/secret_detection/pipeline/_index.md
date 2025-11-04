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

After you [enable pipeline secret detection](#getting-started), scans run in a CI/CD job named `secret_detection`.
You can run scans and view [pipeline secret detection JSON report artifacts](../../../../ci/yaml/artifacts_reports.md#artifactsreportssecret_detection) in any GitLab tier.

With GitLab Ultimate, pipeline secret detection results are also processed so you can:

- See them in the [merge request widget](../../detect/security_scanning_results.md), [pipeline security report](../../detect/security_scanning_results.md), and [vulnerability report](../../vulnerability_report/_index.md).
- Use them in approval workflows.
- Review them in the security dashboard.
- [Automatically respond](../automatic_response.md) to leaks in public repositories.
- Enforce consistent secret detection rules across projects by using [security policies](../../policies/_index.md).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> For an interactive reading and how-to demo of this pipeline secret detection documentation see:

- [How to enable secret detection in GitLab Application Security Part 1/2](https://youtu.be/dbMxeO6nJCE?feature=shared)
- [How to enable secret detection in GitLab Application Security Part 2/2](https://youtu.be/VL-_hdiTazo?feature=shared)

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> For other interactive reading and how-to demos, see the [Get Started With GitLab Application Security Playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9).

## Availability

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/).

| Capability                                                              | In Free & Premium                    | In Ultimate |
|:------------------------------------------------------------------------|:-------------------------------------|:------------|
| [Customize analyzer behavior](configure.md#customize-analyzer-behavior) | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes |
| Download [output](#secret-detection-results)                            | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes |
| See new findings in the merge request widget                            | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| View identified secrets in the pipelines' **Security** tab              | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| [Manage vulnerabilities](../../vulnerability_report/_index.md)          | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| [Access the security dashboard](../../security_dashboard/_index.md)     | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| [Customize analyzer rulesets](configure.md#customize-analyzer-rulesets) | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| [Enable security policies](../../policies/_index.md)                    | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |

## Getting started

To get started with pipeline secret detection, select a pilot project and enable the analyzer.

Prerequisites:

- You have a Linux-based runner with the [`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
  [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
  If you use hosted runners for GitLab.com, this is enabled by default.
  - Windows Runners are not supported.
  - CPU architectures other than amd64 are not supported.
- You have a `.gitlab-ci.yml` file that includes the `test` stage.

Enable the secret detection analyzer by using one of the following:

- Edit the `.gitlab-ci.yml` file manually. Use this method if your CI/CD configuration is complex.
- Use an automatically configured merge request. Use this method if you don't have a CI/CD configuration, or your configuration is minimal.
- Enable pipeline secret detection in a [scan execution policy](../../policies/scan_execution_policies.md).

If this is your first time running a secret detection scan on your project, you should run a historic scan immediately after you enable the analyzer.

After you enable pipeline secret detection, you can [customize the analyzer settings](configure.md).

### Edit the `.gitlab-ci.yml` file manually

This method requires you to manually edit an existing `.gitlab-ci.yml` file.

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Build** > **Pipeline editor**.
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
Consider [running a historic scan](#run-a-historic-scan) after you enable the analyzer.

### Use an automatically configured merge request

This method automatically prepares a merge request to add a `.gitlab-ci.yml` file that includes the pipeline secret detection template. Merge the merge request to enable pipeline secret detection.

To enable pipeline secret detection:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Security configuration**.
1. In the **Pipeline secret detection** row, select **Configure with a merge request**.
1. Optional. Complete the fields.
1. Select **Create merge request**.
1. Review and merge the merge request.

Pipelines now include a pipeline secret detection job.

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
    This means the current repository state is scanned as though it were a typical directory.
  - On a **new, non-default branch**, the content of all commits from the most recent commit on the parent branch to the latest commit is scanned.
  - On an **existing, non-default branch**, the content of all commits from the last pushed commit to the latest commit is scanned.
- On a **merge request**, the content of all commits on the branch is scanned. If the analyzer can't access every commit,
  the content of all commits from the parent to the latest commit is scanned. To scan all commits, you must enable
  [merge request pipelines](../../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines).

To override the default behavior, use the [available CI/CD variables](configure.md#available-cicd-variables).

### How the analyzer fetches commits

By default, when GitLab first clones a repository, it fetches only the most recent commits (a "shallow clone").
When additional commits are needed beyond this initial clone, the analyzer automatically fetches them using optimized strategies:

- For merge requests, the analyzer retrieves only changes committed after the merge base, which minimizes data transfer.
- If log options are specified, like `--since` or `--max-count`, the analyzer fetches only the required commits.
- During a historic scan, the analyzer fetches the complete repository history. If the repository was shallowly cloned, the analyzer uses the `--unshallow` option.

If the analyzer cannot fetch the required commits, it falls back to scanning available data:

- After a force push, the analyzer scans only the current state of the repository.
- If there are network failures, the analyzer scans commits available after the initial clone.
- If there are timeouts, the analyzer continues the scan with a partial commit history.

These fallbacks ensure your pipeline completes successfully, even in restricted environments.

### Initial repository clone depth

The runner's [`GIT_DEPTH`](../../../../ci/runners/configure_runners.md#shallow-cloning) controls how many commits are initially cloned. Pipeline secret detection automatically fetches additional commits when needed, so you typically don't need to adjust this setting.

If you experience persistent issues with missing commits in restricted network environments, see the troubleshooting for workarounds.

### Run a historic scan

By default, pipeline secret detection scans only the current state of the Git repository. Any secrets
contained in the repository's history are not detected. Run a historic scan to check for secrets from
all commits and branches in the Git repository.

You should run a historic scan only once, after enabling pipeline secret detection. Historic scans
can take a long time, especially for larger repositories with lengthy Git histories. After
completing an initial historic scan, use only standard pipeline secret detection as part of your
pipeline.

If you enable pipeline secret detection with a [scan execution policy](../../policies/scan_execution_policies.md#scanner-behavior),
by default the first scheduled scan is a historic scan.

To run a historic scan:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Build** > **Pipelines**.
1. Select **New pipeline**.
1. Add a CI/CD variable:
   1. From the dropdown list, select **Variable**.
   1. In the **Input variable key** box, enter `SECRET_DETECTION_HISTORIC_SCAN`.
   1. In the **Input variable value** box, enter `true`.
1. Select **New pipeline**.

### Duplicate vulnerability tracking

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/434096) in GitLab 17.0.

{{< /history >}}

Secret detection uses an advanced vulnerability tracking algorithm to prevent
duplicate findings and vulnerabilities from being created when a file is
refactored or moved.

A new finding is not created when:

- A secret is moved within a file.
- A duplicate secret appears within a file.

Duplicate vulnerability tracking works on a per-file basis.
If the same secret appears in two different files, two findings are created.

For more information, see the confidential project `https://gitlab.com/gitlab-org/security-products/post-analyzers/tracking-calculator`.
This project is available only to GitLab team members.

#### Unsupported workflows

Duplicate vulnerability tracking doesn't support workflows where:

- The existing finding lacks a tracking signature and doesn't share the same location as the new finding.
- Certain secrets are detected by searching for their prefixes instead of the entire secret value. For these secret types, all the detections of the same type and in the same file are reported as a single finding.

  For example, an SSH private key is detected by its prefix `-----BEGIN OPENSSH PRIVATE KEY-----`. If there are multiple SSH private keys in the same file,
  pipeline secret detection creates only one finding.
- When running a historic scan or enabling pipeline secret detection on existing commits, if a secret is introduced in one commit and then modified in a later commit during the same scan, only the most recent secret value appears in the vulnerability report.

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
run again. This is because the leaked secret continues to be a security risk until it has been revoked.
Removed secrets also persist in the Git history. To remove a secret from the Git repository's history, see
[Redact text from repository](../../../project/repository/repository_size.md#redact-text-from-repository).

### Excluded items

To improve performance, pipeline secret detection automatically excludes certain file types and directories with a low likelihood of containing secrets.

The following items are excluded:

| Category                            | Excluded items                                                                                                                                                                                                                                                                                                                                                                                                                                             |
|-------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Configuration files             | Files: `gitleaks.toml`, `verification-metadata.xml`, `Database.refactorlog`, `.editorconfig`, `.gitattributes`                                                                                                                                                                                                                                                                                                                                             |
| Media and binary files           | Extensions: `.bmp`, `.gif`, `.svg`, `.jpg/.jpeg`, `.png`, `.tiff/.tif`, `.webp`, `.ico`, `.heic`<br/>Fonts: `.eot`, `.otf`, `.ttf`, `.woff`, `.woff2`<br/>Documents: `.doc/.docx`, `.xls/.xlsx`, `.ppt/.pptx`, `.pdf`<br/>Audio/video: `.mp3`, `.mp4`, `.wav`, `.flac`, `.aac`, `.ogg`, `.avi`, `.mkv`, `.mov`, `.wmv`, `.flv`, `.webm`<br/>Archives: `.zip`, `.rar`, `.7z`, `.tar`, `.gz`, `.bz2`, `.xz`, `.dmg`, `.iso`<br/>Executables: `.exe`, `.gltf` |
| Visual Studio files             | Extensions: `.socket`, `.vsidx`, `.suo`, `.wsuo`, `.dll`, `.pdb`                                                                                                                                                                                                                                                                                                                                                                                           |
| Package lock files              | Files: `deno.lock`, `npm-shrinkwrap.json`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `Pipfile.lock`, `poetry.lock`, `gradle.lockfile`, `Cargo.lock`, `composer.lock`                                                                                                                                                                                                                                                                             |
| Go language files               | Extensions: `go.mod`, `go.sum`, `go.work`, `go.work.sum`<br/>Directories: `vendor/` (only for Go modules from `github.com`, `golang.org`, `google.golang.org`, `gopkg.in`, `istio.io`, `k8s.io`, `sigs.k8s.io`)<br/>Files: `vendor/modules.txt`                                                                                                                                                                                                            |
| Ruby files                      | Directories: `.bundle/`, `gems/`, `specifications/`<br/>Extensions: `.gem` files in `gems/` directory, `.gemspec` files in `specifications/` directory                                                                                                                                                                                                                                                                                                     |
| Build tool wrappers             | Files: `gradlew`, `gradlew.bat`, `mvnw`, `mvnw.cmd`<br/>Directories: `.mvn/wrapper/`<br/>Specific: `MavenWrapperDownloader.java` in Maven wrapper directory                                                                                                                                                                                                                                                                                                |
| Dependency directories          | Directories: `node_modules/`, `bower_components/`, `packages/`                                                                                                                                                                                                                                                                                                                                                                                             |
| Build output directories        | Directories: `target/`, `build/`, `bin/`, `obj/`                                                                                                                                                                                                                                                                                                                                                                                                           |
| Vendor directories             | Directories: `vendor/bundle/`, `vendor/ruby/`, `vendor/composer/`                                                                                                                                                                                                                                                                                                                                                                                          |
| Python cache files              | Extensions: `.pyc`, `.pyo`<br/>Directories: `__pycache__/`                                                                                                                                                                                                                                                                                                                                                                                                 |
| Python tool caches              | Directories: `.pytest_cache/`, `.mypy_cache/`, `.tox/`                                                                                                                                                                                                                                                                                                                                                                                                     |
| Python virtual environments     | Directories: `venv/`, `virtualenv/`, `.venv/`, `env/`                                                                                                                                                                                                                                                                                                                                                                                                      |
| Python installation directories | Directories: `lib/python[version]/`, `lib64/python[version]/`, `python[version]/lib/`, `python[version]/Lib/`                                                                                                                                                                                                                                                                                                                                              |
| Python package metadata        | Package names ending with version and `.dist-info`                                                                                                                                                                                                                                                                                                                                                                                                         |
| JavaScript libraries            | Files: `angular*.js`, `bootstrap*.js`, `jquery*.js`, `jquery-ui*.js`, `plotly*.js`, `swagger-ui*.js` <br/>Source Maps: Corresponding `.js.map` files                                                                                                                                                                                                                                                                                                       |
| Minified/bundled assets         | Extensions: `.min.js`, `.min.css`, `.bundle.js`, `.bundle.css`, `.map` (source map files)                                                                                                                                                                                                                                                                                                                                                                  |
| Compiled files                  | Extensions: `.class`, `.o`, `.obj`, `.jar`, `.war` (Web archive), `.ear`                                                                                                                                                                                                                                                                                                                                                                                   |
| Cache directories             | Directories: `.cache/`, `.coverage/`, `.pytest_cache/`, `.mypy_cache/`, `.tox/`                                                                                                                                                                                                                                                                                                                                                                            |
| Generated documentation         | Directories: `htmlcov/`, `coverage/`, `_build/`, `_site/`, `docs/_build/`                                                                                                                                                                                                                                                                                                                                                                                  |
| Version control and IDEs           | Directories: `.git/`, `.svn/`, `.hg/`, `.bzr/` (version control), `.vscode/`, `.idea/`, `.eclipse/`, `.vs/` (IDEs)                                                                                                                                                                                                                                                                                                                                         |
| Operating system files          | Files: `.DS_Store`, `Thumbs.db`                                                                                                                                                                                                                                                                                                                                                                                                                            |

## Secret detection results

Pipeline secret detection outputs the file `gl-secret-detection-report.json` as a job artifact. The file contains detected secrets. You can [download](../../../../ci/jobs/job_artifacts.md#download-job-artifacts) the file for processing outside GitLab.

For more information, see the [report file schema](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/secret-detection-report-format.json) and the [example report file](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/qa/expect/secrets/gl-secret-detection-report.json).

### Additional output

{{< details >}}

- Tier: Ultimate

{{< /details >}}

Job results are also reported on the:

- [Merge request widget](../../detect/security_scanning_results.md#merge-request-security-widget): shows new findings introduced in the merge request.
- [Pipeline security report](../../detect/security_scanning_results.md): displays all findings from the latest pipeline run.
- [Vulnerability report](../../vulnerability_report/_index.md): provides centralized management of all security findings.
- Security dashboard: offers organization-wide visibility into all vulnerabilities across projects and groups.

## Understanding the results

Pipeline secret detection provides detailed information about potential secrets found in your repository. Each secret includes the type of secret leaked and remediation guidelines.

When reviewing results:

1. Look at the surrounding code to determine if the detected pattern is actually a secret.
1. Test whether the detected value is a working credential.
1. Consider the repository's visibility and the secret's scope.
1. Address active, high-privilege secrets first.

### Common detection categories

Detections by pipeline secret detection often fall into one of three categories:

- **True positives**: Legitimate secrets that should be rotated and removed. For example:
  - Active API keys, database passwords, authentication tokens
  - Private keys and certificates
  - Service account credentials
- **False positives**: Detected patterns that aren't actual secrets. For example:
  - Example values in documentation
  - Test data or mock credentials
  - Configuration templates with placeholder values
- **Historical findings**: Secrets that were previously committed but might not be active. These detections:
  - Require investigation to determine current status
  - Should still be rotated as a precaution

## Remediate a leaked secret

When a secret is detected, you should rotate it immediately. GitLab attempts to
[automatically revoke](../automatic_response.md) some types of leaked secrets. For those that are not
automatically revoked, you must do so manually.

[Purging a secret from the repository's history](../../../project/repository/repository_size.md#purge-files-from-repository-history)
does not fully address the leak. The original secret remains in any existing forks or
clones of the repository.

For instructions on how to respond to a leaked secret, select the vulnerability in the vulnerability report.

## Optimization

Before deploying pipeline secret detection across your organization, optimize the configuration to reduce false positives and improve accuracy for your specific environment.

False positives can create alert fatigue and reduce trust in the tool. Consider using custom ruleset configuration (Ultimate only):

- Exclude known safe patterns specific to your codebase.
- Adjust sensitivity for rules that frequently trigger on non-secrets.
- Add custom rules for organization-specific secret formats.

To optimize performance in large repositories or organizations with many projects, review your:

- Scan scope management:
  - Turn off historical scanning after you run a historical scan in a project.
  - Schedule historic scans during low-usage periods.
- Resource allocation:
  - Allocate sufficient runner resources for larger repositories.
  - Consider dedicated runners for security scanning workloads.
  - Monitor scan duration and optimize based on repository size.

### Testing optimization changes

Before applying optimizations organization-wide:

1. Validate that optimizations don't miss legitimate secrets.
1. Track false positive reduction and scan performance improvements.
1. Maintain records of effective optimization patterns.

## Roll out

You should implement pipeline secret detection incrementally.
Start with a small-scale pilot to understand the tool's behavior before rolling out the feature across your organization.

Follow these guidelines when you roll out pipeline secret detection:

1. Choose a pilot project. Suitable projects have:
   - Active development with regular commits.
   - A manageable codebase size.
   - A team familiar with GitLab CI/CD.
   - Willingness to iterate on configuration.
1. Start simple. Enable pipeline secret detection with default settings on your pilot project.
1. Monitor results. Run the analyzer for one or two weeks to understand typical findings.
1. Address detected secrets. Remediate any legitimate secrets found.
1. Tune your configuration. Adjust settings based on initial results.
1. Document the implementation. Record common false positives and remediation patterns.

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

For information on this, see the [general application security troubleshooting section](../../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload).

#### Error: `Couldn't run the gitleaks command: exit status 2`

This error indicates the analyzer cannot access required commits. While the analyzer automatically fetches missing commits in most cases, issues can occur in restricted environments.

To diagnose the issue, enable [debug-level logging](../../troubleshooting_application_security.md#debug-level-logging) and look for:

```plaintext
ERRO[2020-11-18T18:05:52Z] object not found
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Couldn't run the gitleaks command: exit status 2
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Gitleaks analysis failed: exit status 2
```

To resolve this issue:

- For most cases, no action is required. Let the analyzer handle fetching automatically.
- For restricted networks, increase the initial clone depth:

  ```yaml
  secret_detection:
    variables:
      GIT_DEPTH: 100  # or 0 to clone everything
  ```

- For large repositories, limit the scan scope:

  ```yaml
  secret_detection:
    variables:
      SECRET_DETECTION_LOG_OPTIONS: "--max-count=50"
  ```

#### Error: `ERR fatal: ambiguous argument`

Pipeline secret detection can fail with the message `ERR fatal: ambiguous argument` error if your
repository's default branch is unrelated to the branch the job was triggered for. See issue
[!352014](https://gitlab.com/gitlab-org/gitlab/-/issues/352014) for more details.

To resolve the issue, make sure to correctly [set your default branch](../../../project/repository/branches/default.md#change-the-default-branch-name-for-a-project)
on your repository. You should set it to a branch that has related history with the branch you run
the `secret-detection` job on.

#### `exec /bin/sh: exec format error` message in job log

The GitLab pipeline secret detection analyzer [only supports](#getting-started) running on the `amd64` CPU architecture.
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

#### Adjusting `GIT_DEPTH` doesn't change what gets scanned

This is expected behavior. `GIT_DEPTH` is a runner variable for the initial clone. It doesn't change analyzer behavior.

The secret detection analyzer decides what to scan based on:

- Pipeline type (push, merge request, scheduled)
- Branch context (default, new, existing)
- Your configuration (`SECRET_DETECTION_LOG_OPTIONS`, `SECRET_DETECTION_HISTORIC_SCAN`)

For example, to scan only 30 commits:

```yaml
secret_detection:
  variables:
    # Scan the last 30 commits
    SECRET_DETECTION_LOG_OPTIONS: "--max-count=30"
```

To scan only commits from the last two weeks:

```yaml
secret_detection:
  variables:
    # Scan commits made in the last two weeks
    SECRET_DETECTION_LOG_OPTIONS: "--since=2.weeks"
```

To scan only commits from `HEAD~10` to `HEAD`:

```yaml
secret_detection:
  variables:
    # Scan commits from HEAD~10 to HEAD
    SECRET_DETECTION_LOG_OPTIONS: "HEAD~10..HEAD"
```

For a full list of options, see the [Git log options](https://git-scm.com/docs/git-log) documentation.

#### Force push detection

After a force push, you might see:

```plaintext
Failed to retrieve all the commits from the last Git push event due to a force push
```

This is expected behavior. The scan continues using the current repository state.

#### Repository trust configuration

You might see the message:

```plaintext
Added project directory to Git safe.directory configuration
```

This indicates typical security configuration in containerized environments. No action is required.

<!-- markdownlint-enable MD025 -->
