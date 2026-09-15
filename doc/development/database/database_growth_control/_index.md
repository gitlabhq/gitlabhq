---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
description: Frameworks and guidance for keeping GitLab database tables growth under control.
title: Database growth control
---

GitLab monolith uses postgres database for OLTP but often times data that gets into it does not have any
lifecycle defined, which resulted in increasing database size by holding data which should not be sitting in them.

Multiple efforts are being done as part [Data Growth Control](https://gitlab.com/groups/gitlab-org/-/work_items/22105)
epic to ensure the database stays under control and tools are built to facilitate moving data out of PgSQL when necessary.

- [Data retention policy](data_retention_policy.md)
