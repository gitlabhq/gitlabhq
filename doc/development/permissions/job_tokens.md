---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Job token permission development guidelines
---

## Background

Historically, job tokens have provided broad access to resources by default. With the introduction of
fine-grained permissions for job tokens, we can enable granular access controls while adhering to the
principle of least privilege.

This topic provide guidance on the requirements and contribution guidelines for new job token permissions.

## Requirements

Before being accepted, all new job token permissions must:

- Be opt-in and disabled by default.
- Complete a review by the GitLab security team.
  - Tag `@gitlab-com/gl-security/product-security/appsec` for review

These requirements ensure that new permissions allow users to maintain explicit control over their security configuration, prevent unintended privilege escalation, and adhere to the principle of least privilege.
