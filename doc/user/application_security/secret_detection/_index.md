---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Secret detection
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Your application might use external resources, including a CI/CD
service, a database, or external storage. Access to these resources
requires authentication, usually using static methods like private
keys and tokens. These methods are called "secrets" because they're
not meant to be shared with anyone else.

To minimize the risk of exposing your secrets, always [store secrets outside of the repository](../../../ci/secrets/_index.md). However, secrets are sometimes accidentally committed to Git
repositories. After a sensitive value is pushed to a remote
repository, anyone with access to the repository can use the secret to
impersonate the authorized user.

Secret detection monitors your activity to both:

- Help prevent your secrets from being leaked.
- Help you respond if a secret is leaked.

You should take a multi-layered security approach and enable all available secret detection methods:

- [Secret push protection](secret_push_protection/_index.md) scans commits for secrets when you
  push changes to GitLab. The push is blocked if secrets are detected, unless you skip secret push protection.
  This method reduces the risk of secrets being leaked.
- [Pipeline secret detection](pipeline/_index.md) runs as part of a project's CI/CD pipeline. Commits
  to the repository's default branch are scanned for secrets. If pipeline secret detection is
  enabled in merge request pipelines, commits to the development branch are scanned for secrets,
  enabling you to respond before they're committed to the default branch.
- [Client-side secret detection](client/_index.md) scans descriptions and comments in both issues and
  merge requests for secrets before they're saved to GitLab. When a secret is detected you can
  choose to edit the input and remove the secret or, if it's a false positive, save the description
  or comment.

If a secret is committed to a repository, GitLab records the exposure
in the Vulnerability Report. For some secret types, GitLab can even
automatically revoke the exposed secret. You should always revoke and
replace exposed secrets as soon as possible.

## Related topics

- [Secret detection exclusions](exclusions.md)
- [Vulnerability Report](../vulnerability_report/_index.md)
- [Automatic response to leaked secrets](automatic_response.md)
- [Push rules](../../project/repository/push_rules.md)
