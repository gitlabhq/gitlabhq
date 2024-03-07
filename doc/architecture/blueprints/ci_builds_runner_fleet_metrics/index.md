---
status: proposed
creation-date: "2023-01-25"
authors: [ "@pedropombeiro", "@vshushlin"]
coach: "@grzesiek"
approvers: [  ]
stage: Verify
group: Runner
participating-stages: []
---

# CI Builds and Runner Fleet metrics database architecture

The CI section envisions new value-added features in GitLab for CI Builds and Runner Fleet focused on observability and automation. However, implementing these features and delivering on the product vision of observability, automation, and AI optimization using the current database architecture in PostgreSQL is very hard because:

- CI-related transactional tables are huge, so any modification to them can increase the load on the database and subsequently cause incidents.
- PostgreSQL is not optimized for running aggregation queries.
- We also want to add more information from the build environment, making CI tables even larger.
- We also need a data model to aggregate data sets for the GitLab CI efficiency machine learning models - the basis of the Runner Fleet AI solution

We want to create a new flexible database architecture which:

- will support known reporting requirements for CI builds and Runner Fleet.
- can be used to ingest data from the CI build environment.

We may also use this database architecture to facilitate development of AI features in the future.

Our recent usability research on navigation and other areas suggests that the GitLab UI is overloaded with information and navigational elements.
This results from trying to add as much information as possible and attempting to place features in the most discoverable places.
Therefore, while developing these new observability features, we will rely on the jobs to be done research, and solution validation, to ensure that the features deliver the most value.

## Runner Fleet

### Metrics - MVC

#### What is the estimated wait time in queue for an instance runner?

The following customer problems should be solved when addressing this question. Most of them are quotes from our usability research

**UI**

- "There is no visibility for expected Runner queue wait times."
- "I got here looking for a view that makes it more obvious if I have a bottleneck on my specific runner."

**Types of metrics**

- "Is it possible to get metrics out of GitLab to check for the runners availability & pipeline wait times?
  Goal - we need the data to evaluate the data to determine if to scale up the Runner fleet so that there is no waiting times for developer’s pipelines."
- "What is the estimated time in the Runner queue before a job can start?"

**Interpreting metrics**

- "What metrics for Runner queue performance should I look at and how do I interpret the metrics and take action?"
- "I want to be able to analyze data on Runner queue performance over time so that I can determine if the reports are from developers are really just rare cases regarding availability."

#### What is the estimated wait time in queue on a group runner?

#### What is the mean estimated wait time in queue for all instance runners?

#### What is the mean estimated wait time in queue for all group runners?

#### Which runners have failures in the past hour?

## CI Insights

CI Insights is a page that would mostly expose data on pipelines and jobs duration, with a multitude of different filters, search and dynamic graphs. To read more on this, see [this related sub-section](ci_insights.md).

## Implementation

The current implementation plan is based on a
[Proof of Concept](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126863).
For an up to date status, see [epic 10682](https://gitlab.com/groups/gitlab-org/-/epics/10682).

### Database selection

In FY23, ClickHouse [was selected as GitLab standard datastore](https://handbook.gitlab.com/handbook/company/working-groups/clickhouse-datastore/#context)
for features with big data and insert-heavy requirements.
So we have chosen it for our CI analytics as well.

### Scope of data

We're starting with the denormalized version of the `ci_builds` table in the main database,
which will include fields from some other tables. For example, `ci_runners` and `ci_runner_machines`.

[Immutability is a key constraint in ClickHouse](../../../development/database/clickhouse/index.md#how-it-differs-from-postgresql),
so we only use `finished` builds.

### Developing behind feature flags

It's hard to fully test data ingestion and query performance in development/staging environments.
That's why we plan to deliver those features to production behind feature flags and test the performance on real data.
Feature flags for data ingestion and APIs will be separate.

### Data ingestion

Every time a job finished, a record will be created in a new `p_ci_finished_build_ch_sync_events` table, which includes
the `build_id` and a `processed` value.
A background worker loops through unprocessed `p_ci_finished_build_ch_sync_events` records and push the denormalized
`ci_builds` information from Postgres to ClickHouse.

At some point we most likely will need to
[parallelize this worker because of the number of processed builds](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126863#note_1494922639).
This will be achieved by having the cron worker accept an argument determining the number of workers. The cron worker
will use that argument to queue the respective number of workers that will actually perform the syncing to ClickHouse.

We will start with most recent builds and will not upload all historical data.

### "Raw data", materialized views and queries

Ingested data will go to the "raw data" table in ClickHouse.
This table will use `ReplacingMergeTree` engine to deduplicate rows in case data ingestion mechanism accidentally submits the same batch twice.

Raw data can be used directly do execute queries, but most of the time we will create specialized materialized views
using `AggregatingMergeTree` engine.
This will allow us to read significantly less data when performing queries.

### Limitations and open questions

The topics below require further investigation.

#### Efficient way of querying data for namespaces

We start with the PoC available only for administrators,
but very soon we will need to implement features on the group level.

We can't just put denormalized "path" in the source table because it can be changed when groups or projects are moved.

The simplest way of solving this is to always filter builds by `project_id`,
but this may be inefficient and require reading a significant portion of all data because ClickHouse stores data in big batches.

#### Keeping the database schema up to date

Right now we don't have any mechanism equivalent to migrations we use for PostgreSQL.
While developing our first features we will maintain database schema by hand and
continue developing mechanisms for migrations.

#### Re-uploading data after changing the schema

If we need to modify database schema, old data maybe incomplete.
In that case we can simply truncate the ClickHouse tables and re-upload (part of) the data.
