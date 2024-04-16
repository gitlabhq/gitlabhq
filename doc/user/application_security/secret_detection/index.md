---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Secret Detection

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> [In GitLab 14.0](https://gitlab.com/gitlab-org/gitlab/-/issues/297269), Secret Detection jobs `secret_detection_default_branch` and `secret_detection` were consolidated into one job, `secret_detection`.

People sometimes accidentally commit secrets like keys or API tokens to Git repositories. After a
sensitive value is pushed to a remote repository, anyone with access to the repository can
impersonate the authorized user of the secret for malicious purposes. Most organizations require
exposed secrets to be revoked and replaced to address this risk.

Secret Detection scans your repository to help prevent your secrets from being exposed. Secret
Detection scanning works on all text files, regardless of the language or framework used.

GitLab has two methods for detecting secrets which can be used simultaneously:

- The [pipeline](pipeline/index.md) method detects secrets during the project's CI/CD pipeline. This method cannot reject pushes.
- The [pre-receive](pre_receive/index.md) method detects secrets when users push changes to the
  remote Git branch. This method can reject pushes if a secret is detected.

A secret detected during a secret detection scan remains in the [vulnerability report](../vulnerability_report/index.md) as "Still detected" even after the secret is removed from the scanned file. This is because a secret remains in the Git repository's history. To address a detected secret, remediate the leak, then triage the vulnerability.
