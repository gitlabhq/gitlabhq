---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Application and rate limit guidelines
---

GitLab, like most large applications, enforces limits in certain features.
The absences of limits can affect security, performance, data, or could even
exhaust the allocated resources for the application.

Every new feature should have safe usage limits included in its implementation.
Limits are applicable for:

- System-level resource pools such as API requests, SSHD connections, database connections, and storage.
- Domain-level objects such as compute quota, groups, and sign-in attempts.

## When limits are required

1. Limits are required if the absence of the limit matches severity 1 - 3 in the severity definitions for [limit-related bugs](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#limit-related-bugs).
1. [GitLab application limits](../../administration/instance_limits.md) documentation must be updated anytime limits are added, removed, or updated.

## Additional reading

- Existing [GitLab application limits](../../administration/instance_limits.md)
- Product processes: [introducing application limits](https://handbook.gitlab.com/handbook/product/product-processes/#introducing-application-limits)
- Development documentation: [guide for adding application limits](../application_limits.md)
