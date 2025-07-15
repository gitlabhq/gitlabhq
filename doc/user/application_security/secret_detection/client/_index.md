---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Client-side secret detection
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368434) in GitLab 15.11.
- Detection of personal access tokens with a custom prefix was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/411146) in GitLab 16.1. GitLab Self-Managed only.

{{< /history >}}

When you create an issue, add a description to a merge request, or write a comment, you might accidentally post a
secret. For example, you might paste in the details of an API request or an environment variable
that contains an authentication token. If a secret is leaked, an adversary can use it to impersonate a legitimate user.

Client-side secret detection helps minimize the risk of accidental secret exposure. When you edit a
description, or comment in an issue or merge request, GitLab automatically scans the content for secrets.

## Secret detection workflow

Client-side secret detection operates entirely within your browser using pattern matching. This approach ensures that:

- Secrets are detected before they are submitted to GitLab.
- No sensitive information is transmitted during the detection process.
- The feature works seamlessly without requiring additional configuration.

## Getting started

Client-side secret detection is enabled by default for all GitLab tiers. No setup or configuration is required.

To test this feature:

1. Navigate to any issue or merge request
1. Add a comment containing a test secret pattern, such as `glpat-xxxxxxxxxxxxxxxxxxxx`
1. Observe the warning message that appears before you submit

Always use placeholder values when you test to avoid exposing real secrets.

## Coverage

Client-side secret detection analyzes the following content:

- Issue descriptions and comments
- Merge request descriptions and comments

For detailed information about the specific types of secrets detected, see the [Detected secrets](../detected_secrets.md) documentation.

## Understanding the results

When client-side secret detection identifies a potential secret, GitLab displays a warning that highlights the detected secret.
You can either:

- **Edit** the content of the comment or description to remove the secret.
- **Add** content without making any changes. Exercise caution before you add content that contains a potential secret.

The detection occurs entirely in your browser. No information is transmitted unless you select **Add**.

## Optimization

To maximize the effectiveness of client-side secret detection:

- Review warnings carefully. Always investigate flagged content before proceeding.
- Use placeholders. Replace actual secrets with placeholder text like `[REDACTED]` or `<API_KEY>`.
