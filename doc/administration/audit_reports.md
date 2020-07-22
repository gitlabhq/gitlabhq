---
stage: Manage
group: Compliance
description: 'Learn how to create evidence artifacts typically requested by a 3rd party auditor.'
---

# Audit Reports

GitLab can help owners and administrators respond to auditors by generating
comprehensive reports. These **Audit Reports** vary in scope, depending on the
need:

## Use cases

- Generate a report of audit events to provide to an external auditor requesting proof of certain logging capabilities.
- Provide a report of all users showing their group and project memberships for a quarterly access review so the auditor can verify compliance with an organization's access management policy.

## APIs

- `https://docs.gitlab.com/ee/api/audit_events.html`
- `https://docs.gitlab.com/ee/api/graphql/reference/#user`
- `https://docs.gitlab.com/ee/api/graphql/reference/#groupmember`
- `https://docs.gitlab.com/ee/api/graphql/reference/#projectmember`

## Features

- `https://docs.gitlab.com/ee/administration/audit_events.html`
- `https://docs.gitlab.com/ee/administration/logs.html`

We plan on making Audit Events [downloadable as a CSV](https://gitlab.com/gitlab-org/gitlab/-/issues/1449)
in the near future.
