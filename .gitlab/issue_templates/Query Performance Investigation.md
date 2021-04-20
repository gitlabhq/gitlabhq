## Description

As the name implies, the purpose of the template is to detail underperforming queries for further investigation.

### Steps

- [ ] Rename the issue to - `Query Performance Investigation - [Query Snippet | Table info]`
  - For example - `Query Performance Investigation - SELECT "namespaces".* FROM "namespaces" WHERE "namespaces"."id" = $1 LIMIT $2`
- [ ] Provide information in the Requested Data Points table
- [ ] Provide [priority and severity labels](https://about.gitlab.com/handbook/engineering/quality/issue-triage/#availability)
- [ ] If this requires immediate attention cc `@gitlab-org/database-team` and reach out in the #g_database slack channel

### SQL Statement

```sql

```

### Data from Elastic

Instructions on collecting data from [PostgreSQL slow logs stored in Elasticsearch](https://gitlab.com/gitlab-com/runbooks/-/merge_requests/3361/diffs)

### Requested Data points

Please provide as many of these fields as possible when submitting a query performance report.

- Queries per second (on average or peak)
- Number of calls per second and relative to total number of calls
- Query timings (on average or peak)
- Database time relative to total database time
- Source of calls (Sidekiq, WebAPI, etc)
- Query ID
- Query Plan
- Query Example
- Total number of calls (relative)
- % of Total time

<!--

- Example of a postgres checkup report - https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/snippets/2056787
- Epic - Improving the Database resource usage (&365) - https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/365#short-term-query-improvements
- Past examples of query performance investigations that have led to this template creation. 
 - Possible Index suggestion or query rewriting (#292454) - https://gitlab.com/gitlab-org/gitlab/-/issues/292454)
 - High number of Sessions to the database with the value SET parameter (#292022) - https://gitlab.com/gitlab-org/gitlab/-/issues/292022)
 - Query performance "Select 1" (#220055) - https://gitlab.com/gitlab-org/gitlab/-/issues/220055
 - Select statements that are in execution during database CPU utilization peak times - licenses table (#292900)  - https://gitlab.com/gitlab-org/gitlab/-/issues/292900

-->

/label ~"group::database" ~"database::triage"
