---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Application and rate limit guidelines

GitLab, like most large applications, enforces limits within certain features.
The absences of limits can affect security, performance, data, or could even
exhaust the allocated resources for the application.

Every new feature should have safe usage limits included in its implementation.
Limits are applicable for:

- System-level resource pools such as API requests, SSHD connections, database connections, storage, and so on.
- Domain-level objects such as CI/CD minutes, groups, sign-in attempts, and so on.

## When limits are required

1. Limits are required if the absence of the limit matches severity 1 - 3 in the severity definitions for [limit-related bugs](https://about.gitlab.com/handbook/engineering/quality/issue-triage/#limit-related-bugs).
1. [GitLab application limits](../../administration/instance_limits.md) documentation must be updated anytime limits are added, removed, or updated.

## Additional reading

- Existing [GitLab application limits](../../administration/instance_limits.md)
- Product processes: [introducing application limits](https://about.gitlab.com/handbook/product/product-processes/#introducing-application-limits)
- Development docs: [guide for adding application limits](../application_limits.md)
