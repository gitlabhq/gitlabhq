---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Group migration by direct transfer

[Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2771) in GitLab 13.7.

WARNING:
This feature is [under construction](https://gitlab.com/groups/gitlab-org/-/epics/2771) and its API/Architecture might change in the future.

[Group migration by direct transfer](../user/group/import/index.md#migrate-groups-by-direct-transfer-recommended) is the
evolution of migrating groups and projects using file exports. The goal is to have an easier way for the user to migrate a whole group,
including projects, from one GitLab instance to another.

## Design decisions

The following architectural diagram illustrates how the Group Migration
works with a set of [ETL](#etl) Pipelines leveraging from the current [GitLab APIs](#api).

![Simplified Component Overview](img/bulk_imports_overview_v13_7.png)

### [ETL](https://www.ibm.com/topics/etl)

<!-- Direct quote from the IBM URL link -->

> ETL, for extract, transform and load, is a data integration process that
> combines data from multiple data sources into a single, consistent data store
> that is loaded into a data warehouse or other target system.

Using ETL architecture makes the code more explicit and easier to follow, test and extend. The
idea is to have one ETL pipeline for each relation to be imported.

### API

The current [project](../user/project/settings/import_export.md) and
[group](../user/group/import/index.md#migrate-groups-by-uploading-an-export-file-deprecated) imports are file based, so
they require an export step to generate the file to be imported.

Group migration by direct transfer leverages the [GitLab API](../api/rest/index.md) to speed the migration.

And, because we're on the road to [GraphQL](../api/graphql/index.md),
Group migration by direct transfer can contribute to expanding GraphQL API coverage, which benefits both GitLab
and its users.

### Namespace

The migration process starts with the creation of a [`BulkImport`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/bulk_import.rb)
record to keep track of the migration. From there all the code related to the
GitLab Group Migration can be found under the new `BulkImports` namespace in all the application layers.
