---
stage: Secure
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Detected secrets

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

This table lists the secrets detected by [client-side secret detection](index.md).

<!-- markdownlint-disable MD044 -->
<!-- markdownlint-disable MD037 -->

| Description                       | Keywords |
|:----------------------------------|:---------|
| GitLab Feed Token                 | glft     |
| GitLab Agent for Kubernetes Token | glagent  |
| GitLab CI Build (Job) Token       | glcbt    |
| GitLab Deploy Token               | gldt     |
| GitLab Feature Flags Client Token | glffct   |
| GitLab Incoming Mail Token        | glimt    |
| GitLab OAuth Application Secret   | gloas    |
| GitLab Personal Access Token      | glpat    |
| GitLab Pipeline Trigger Token     | glptt    |
| GitLab Runner Token               | glrt     |
| GitLab SCIM OAuth Access Token    | glsoat   |
| Anthropic key                     | sk-ant   |

<!-- markdownlint-enable MD037 -->
<!-- markdownlint-enable MD044 -->

## Related topics

- [GitLab Token overview](../../../../security/token_overview.md)
