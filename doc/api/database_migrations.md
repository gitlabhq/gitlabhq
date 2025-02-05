---
stage: Data Access
group: Database Frameworks
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Database migrations API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123408) in GitLab 16.2.

This API is for managing database migrations used in the development of GitLab.

All methods require administrator authorization.

## Mark a migration as successful

Mark pending migrations as successfully executed to prevent them from being
executed by the `db:migrate` tasks. Use this API to skip failing
migrations after they are determined to be safe to skip.

```plaintext
POST /api/v4/admin/migrations/:version/mark
```

| Attribute       | Type           | Required | Description                                                                                                                                                                                      |
|-----------------|----------------|----------|----------------------------------------------------------------------------------|
| `version`       | integer        | yes      | Version timestamp of the migration to be skipped                                 |
| `database`      | string         | no       | The database name for which the migration is skipped. Defaults to `main`.        |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/admin/migrations/:version/mark"
```
