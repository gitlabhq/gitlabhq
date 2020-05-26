---
type: reference, howto
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Secret Detection **(ULTIMATE)**

> [Introduced](https://about.gitlab.com/releases/2019/03/22/gitlab-11-9-released/#detect-secrets-and-credentials-in-the-repository) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.9.

## Overview

A recurring problem when developing applications is that developers may unintentionally commit
secrets and credentials to their remote repositories. If other people have access to the source,
or if the project is public, the sensitive information is then exposed and can be leveraged by
malicious users to gain access to resources like deployment environments.

GitLab 11.9 includes a new check called Secret Detection. It scans the content of the repository
to find API keys and other information that should not be there.

GitLab displays identified secrets as part of the SAST reports visibly in a few places:

- [Security Dashboard](../security_dashboard/)
- Pipelines' **Security** tab
- Report in the merge request widget

![Secret Detection in merge request widget](img/secret-detection-merge-request-ui.png)

## Use cases

- Detecting accidental commit of secrets like keys, passwords, and API tokens.
- Performing a single or recurring scan of the full history of your repository for secrets.

## Configuration

If you already have SAST enabled for your app, you don’t need to take any action to benefit from this
new feature. It is also included in the Auto DevOps default configuration.

Secret Detection is performed by a [specific analyzer](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml#L180)
during the `sast` job. It runs regardless of the programming
language of your app, and you don't need to change your
CI/CD configuration file to enable it. Results are available in the SAST report.

The Secret Detection analyzer includes [Gitleaks](https://github.com/zricethezav/gitleaks) and [TruffleHog](https://github.com/dxa4481/truffleHog) checks.

NOTE: **Note:**
The Secret Detection analyzer will ignore "Password in URL" vulnerabilities if the password begins
with a dollar sign (`$`) as this likely indicates the password being used is an environment
variable. For example, `https://username:$password@example.com/path/to/repo` won't be
detected, whereas `https://username:password@example.com/path/to/repo` would be detected.

## Full History Secret Scan

GitLab 12.11 introduced support for scanning the full history of a reposity. This new functionality
is particularly useful when you are enabling Secret Detection in a repository for the first time and you
want to perform a full secret scan. Running a secret scan on the full history can take a long time,
especially for larger repositories with lengthy Git histories. We recommend not setting this variable
as part of your normal job defintion.

A new configuration variable ([`SAST_GITLEAKS_HISTORIC_SCAN`](../sast/#vulnerability-filters))
can be set to change the behavior of the GitLab Secret Detection scan to run on the entire Git history of a repository.

We have created a [short video walkthrough](https://youtu.be/wDtc_K00Y0A) showcasing how you can perform a full history secret scan.
<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=wDtc_K00Y0A">Walkthrough of historical secret scan</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/wDtc_K00Y0A" frameborder="0" allowfullscreen="true"> </iframe>
</figure>
