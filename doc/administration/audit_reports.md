---
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: 'Learn how to create evidence artifacts typically requested by a 3rd party auditor.'
---

# Audit reports **(FREE)**

GitLab can help owners and administrators respond to auditors by generating
comprehensive reports. These audit reports vary in scope, depending on the
needs.

## Use cases

- Generate a report of audit events to provide to an external auditor requesting proof of certain logging capabilities.
- Provide a report of all users showing their group and project memberships for a quarterly access review so the auditor can verify compliance with an organization's access management policy.

## APIs

- [Audit events](../api/audit_events.md)
- [GraphQL - User](../api/graphql/reference/index.md#user)
- [GraphQL - GroupMember](../api/graphql/reference/index.md#groupmember)
- [GraphQL - ProjectMember](../api/graphql/reference/index.md#projectmember)

## Features

- [Audit events](audit_events.md)
- [Log system](logs.md)
