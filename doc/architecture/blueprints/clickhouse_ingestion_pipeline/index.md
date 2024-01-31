---
status: proposed
creation-date: "2023-01-10"
authors: [ "@ankitbhatnagar", "@ahegyi", "@mikolaj_wawrzyniak" ]
coach: "@grzesiek"
approvers: [ "@nhxnguyen", "@stkerr" ]
owning-stage: "~workinggroup::clickhouse"
participating-stages: [ "~section::ops", "~section::dev" ]
---

# Scalable data ingestion abstraction for ClickHouse

## Table of Contents

- [Summary](#summary)
  - [Why](#why)
  - [How](#how)
- [Motivation](#motivation)
- [Case Studies](#case-studies)
  - [Replicating existing data into ClickHouse](#1-replicating-existing-data-into-clickhouse)
  - [Ingesting large volumes of data into ClickHouse](#2-ingesting-large-volumes-of-data-into-clickhouse)
- [Goals](#goals)
- [Non-goals](#non-goals)
- [General considerations](#general-considerations)
- [Challenges building this](#major-challenges-around-building-such-a-capability)
- [Proposed solution](#proposed-solution)
- [Design & Implementation](#design--implementation)
- [References](#references)

## Summary

Develop a scalable & reliable data ingestion abstraction to help efficiently ingest large volumes of data from high throughput systems into ClickHouse.

### Why

To enable any application at GitLab to write necessary data into ClickHouse regardless of the scale at which they generate data today, or in the future. Refer to [Motivation](#motivation) for why ClickHouse in the first place.

### How

By building a write abstraction (API/Library) that allows a user to write data into ClickHouse and has all necessary configurations, conventions and best-practices around instrumentation, service-discovery, etc, built into it out of the box.

## Motivation

ClickHouse is an online, analytical processing (OLAP) database that powers use-cases that require fetching real-time, aggregated data that does not mutate a lot. ClickHouse is highly performant and can scale to large volumes of data as compared to traditional transactional relational databases (OLTP) such as Postgres, MySQL. For further reading around ClickHouse's capabilities, see [[1]](https://about.gitlab.com/blog/2022/04/29/two-sizes-fit-most-postgresql-and-clickhouse/), [[2]](https://clickhouse.com/blog/migrating-data-between-clickhouse-postgres) and [[3]](https://posthog.com/blog/clickhouse-vs-postgres).

At GitLab, [our current and future ClickHouse uses/capabilities](https://gitlab.com/groups/gitlab-com/-/epics/2075) reference & describe multiple use-cases that could be facilitated by using ClickHouse as a backing datastore. A majority of these talk about the following two major areas of concern:

1. Being able to leverage [ClickHouse's OLAP capabilities](https://clickhouse.com/docs/en/faq/general/olap) enabling underlying systems to perform an aggregated analysis of data, both over short and long periods of time.
1. The fact that executing these operations with our currently existing datasets primarily in Postgres, is starting to become challenging and non-performant.

Looking forward, assuming a larger volume of data being produced by our application(s) and the rate at which it gets produced, the ability to ingest it into a *more* capable system, both effectively and efficiently helps us scale our applications and prepare for business growth.

## Case studies

From an initial assessment of all (reported) use-cases that intend to utilise ClickHouse, the following broad patterns of usage can be observed:

1. Efficiently replicating existing data from other databases into ClickHouse, most prominently Postgres.
1. Directly ingesting large volumes of data into ClickHouse for asynchronous processing, data aggregation & analysis.

The following section(s) explain details of each problem-domain:

### 1. Replicating existing data into ClickHouse

With due reference to our prior work around this, it has been established that logical replication from Postgres is too slow. Instead, we'll need to be able to emit data change events within database transactions which can then get processed asynchronously to write or update corresponding data in ClickHouse.

The following case-studies describe how these groups intend to solve the underlying problem:

- ~group::optimize has been working towards a scalable PostgreSQL data replication strategy which can be implemented on the application layer.

  - [Proposal: Scalable data sync/replication strategy](https://gitlab.com/gitlab-org/gitlab/-/issues/382172) talks about such a strategy and the additional challenges with using Sidekiq for queueing/batching needs.

  - It has been observed that pumping data from `PostgreSQL` into `ClickHouse` directly might not be the right way to approach the problem at hand.

  - In addition to the problems described above, another class of problems when replicating data across systems is also the handling of data backfill and/or data migrations that happen upstream.

- [group::data](https://handbook.gitlab.com/handbook/business-technology/data-team/) has been working around syncing data from some of our Postgres databases into a Snowflake-based data warehouse. See this issue for optioned considered: [List down all possible options for postgres to snowflake pipeline](https://gitlab.com/gitlab-data/gitlab.com-saas-data-pipeline/-/issues/13) before designing the current system in place.

  - With the work done around our [Next Gen GitLab SaaS Data Pipeline](https://docs.google.com/presentation/d/1hVaCY42YhaO5UvgLzp3mbuMYJIFuTFYFJjdhixFTxPE/edit#slide=id.g143a48de8a3_0_0), the data team owns a "custom" pipeline that does incremental data extractions based on an `updated_at` timestamp column. This helps import a significant subset of operational database relations into Snowflake data-warehouse.

  - As the volume of data grows, we can foresee this (ETL) pipeline warranting more time and resources to execute resulting in delays across the time between data being produced and being available in Snowflake data-warehouse.

  - We might also see data inconsistency/incompleteness issues emanating from the current setup since row deletions are not transferred into Snowflake, inflating data volume and skewing analysis. Any information about multiple updates happening between import interval period are also lost.

  - Having a scalable ingestion pipeline that can help replicate data from our databases into an intermediate system and/or ClickHouse in near real-time would help improve the operational characteristics around this system.

### 2. Ingesting large volumes of data into ClickHouse

We need to be able to ingest large volumes of potentially unaggregated data into ClickHouse which may result into a large number of small writes as well. This can have an adverse effect on how ClickHouse processes and stores incoming data. To mitigate this problem, we need to queue & batch smaller writes into larger ones to keep the ingestion pipeline efficient at all times.

The following case-studies describe how each group intends to solve the underlying problem:

- ~group::observability explains their need of ingesting large amounts of data into ClickHouse, with the following two issues:

  - [Proposal: GitLab Observability Platform - Data Ingestion](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/1878) talks about using an external events store, such as Kafka, to first ingest data as received from users, then writing it into ClickHouse in larger batches thereby eliminating the need to write a large number of small writes without hampering write performance from how ClickHouse `MergeTree` processes ingested data.

  - In addition, [ClickHouse: Investigate client-side buffering to batch writes into ClickHouse](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2044) talks about their experimentation with using application-local queueing/batching to work around the problems mentioned above.

- ~"group::analytics instrumentation" has been working on building our analytics offering and recently looking at building and/or improving parts of the system.

  - [Product Analytics Collector Component](https://gitlab.com/groups/gitlab-org/-/epics/9346) talks about replacing Jitsu with Snowplow for collecting and processing tracking events. For more details of the proposal, see [Jitsu replacement](https://gitlab.com/gitlab-org/analytics-section/analytics-instrumentation/proposals/-/blob/62d332baf5701810d9e7a0b2c00df18431e82f22/doc/jitsu_replacement.md).

  - The initial design was prototyped with [Snowplow as Jitsu Replacement PoC](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit/-/merge_requests/37).

  - From the design, it is easy to observe how large amounts of data will be ingested into ClickHouse and could potentially benefit from the use of a scalable ingestion pipeline.

## Goals

### Well-defined, established client abstractions

We want to define and establish a fully-functional application-side abstraction that can help ingest data into ClickHouse without getting in the way of how an application itself is designed while keeping the underlying code backend-agnostic. The proposed abstraction should become the default choice for any applications, core or satellite, at GitLab.

### Support for high throughput in volume of writes

A solution here should enable an application to write any amount of inserts (order of upto 1000-5000 writes per second) to the underlying database efficiently while also allowing for growth as the application scales out. Considering how ClickHouse processes incoming writes, a proposed solution should be able to batch a number of very small writes into larger batches.

### Reliable, consistent delivery of data

A solution here should also ensure reliable & consistent delivery of ingested data into the underlying database minimising undue loss of data before being eventually persisted into ClickHouse.

## Non-goals

### Addressing data types, schemas or formats

At this stage of this proposal, we're not optimizing for addressing which data types, schemas or formats we receive ingested data in. It should be delegated to the backend-specific implementations themselves and not handled within the write abstraction.

### Addressing where our data sources exist today

We're also not addressing any client-side specific details into the design at this point. The write abstraction should only remain a tool for the language in which it is written. As long as an application can use it to write data as any other third-party library, we should be good to build on top of it.

## General Considerations

Having addressed the details of the two aforementioned problem-domains, we can model a proposed solution with the following logical structure:

- Ingestion
  - APIs/SDKs
  - HTTP2/gRPC Sidecar
- Transport & Routing
  - Multi-destination
- Digestion/Compute
  - Enrichment
  - Processing
  - Persisting

## Major challenges around building such a capability

### Self-managed environments

The single, biggest challenge around introducing ClickHouse and related systems would be the ability to make it avaiable to our users running GitLab in self-managed environments. The intended goals of this proposal are intentionally kept within those constraints. It is also prudent to establish that what we're *proposing* here be applicable to applications consuming ClickHouse from inside self-managed environments.

There are ongoing efforts to streamline distribution and deployment of ClickHouse instances for managed environment within the larger scope of [ClickHouse Usage at GitLab](../clickhouse_usage/index.md). A few other issues tackling parts of the aforementioned problem are:

- [Research and understand component costs and maintenance requirements of running a ClickHouse instance with GitLab](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/14384)
- [ClickHouse maintenance and cost research](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116669)

### Wide variety of data sources, their structures & usage patterns

The data that we intend to ingest into ClickHouse can come from a wide variety of data sources and be structured in different schemas or formats. With that considered, it's non-trivial effort to draft a solution that suffices all use-cases efficiently.

Should we decide to build an intermediate ingestion system, any solution should help provide a source/schema/format-agnostic data transport layer with an established, matured client-abstraction to maximise the number of applications that can use it.

### Building on top of our current database infrastructure

Our current database infrastructure operates at a fairly large scale and adding more applications that continuously read/write against it adds to the pressure on the existing resources. It's important we move away any workloads and/or datasets that can be safely processed in a different context altogether.

### Service Discovery

We're still normalising the details around distribution and deployment of ClickHouse clusters and/or instances for our applications. Subject to how we end up doing it, for a client to be able to discover which ClickHouse cluster, shard or table would need to become a part any such solution.

## Proposed Solution

In light of the problems discussed earlier, it'd be in our better interests to allow the usage of an external, intermediate system subject to what one's needs might be especially around the volume & scale of data being writen from an application into ClickHouse.

Therefore, we intend to develop an abstraction that can enable an application to store data into ClickHouse regardless of the scale that they (currently) operate at. It also:

- Facilitates an application to switch from one *technology* to another should their performance and/or scale requirements change over time.
- Allows for backend-specific conventions, configurations & best practices such as instrumentation, service-discovery, etc. to be encoded in one place for all applications to leverage consistently.

## Design & Implementation

### Core assumptions

- We're only going to focus on writing data into ClickHouse as mentioned in aforementioned non-goals. With details of how our data lands into ClickHouse, this document does not (intentionally) address where this data comes from. Some of those details are delegated to the applications generating this data i.e as long as they can consume this abstraction, they should be able to write data into ClickHouse.

- We're going to delegate the choice of different storage backends to a following blueprint or epic since that's outside the scope of this design. With ClickHouse as the eventual destination for our data, this document only talks about writing data into it - either directly or indirectly via a queueing/batching system.

### Architecture

![Architecture](clickhouse_dbwriter.png)

Having an abstraction around writing data help client-side instrumentation to stay backend-agnostic allowing them to switch code paths depending on where it runs.

An example setup should look like:

```ruby
Gitlab::Database::Writer.config do |config|
  #
  # when using sync mode, data gets written directly into ClickHouse,
  # therefore, it's also assumed the backend here is ClickHouse
  config.mode = :sync OR :async
  config.backend = :clickhouse # optional
  # OR
  #
  # when using async mode, data is written to an intermediate system
  # first, then written into ClickHouse asynchronously
  config.mode = :async
  config.backend = :pubsub OR :kafka OR :otherbackend
  #
  # then backend-specific configurations hereafter
  #
  config.url = 'tcp://user:pwd@localhost:9000/database'
  # for example, a serializer helps define how data travels over the wire
  config.json_serializer = ClickHouse::Serializer::JsonSerializer
  # ...
end
# do application-specific processing
# eventually, write data using the object you just built
Gitlab::Database::Writer.write(
  Gitlab::Database::Model::MyTable,
  [{ id: 1, foo: 'bar' }],
)
```

We intend to keep `Gitlab::Database::Writer.backend` to be as close to the backend-specific client implementation as possible. Having a wrapper around a vanilla client helps us address peripheral concerns such as service-discovery for the backends while still allowing the user to leverage features of a given client.

### Iterations

Considering the large scope of this undertaking and the need for feedback around actual usage, we intend to build the proposed abstraction(s) across multiple iterations which can be described as follows:

#### Iteration 1 - Develop write abstraction with sync mode enabled

First, research and develop a simple write abstraction that our users can begin to use to write data into ClickHouse. This ensures our choice of the underlying client is well-researched and suffices to fulfill needs of as many reported use-cases as possible. Being able to see this running would help gather user-feedback and improve the write APIs/interfaces accordingly.

Given this feedback and more development with how we aim to deploy ClickHouse across our environments, it'd then be prudent to build into this abstraction necessary conventions, best practices and abstract away details around connection-pooling, service-discovery, etc.

#### Iteration 2 - Add support for schemas & data validation

In the next iteration, we plan to add support for schema usage and validation. This helps keep model definitions sane and allows for validating data to be inserted.

#### Iteration 3 - Add support for async mode, PoC with one backend

With the above two iterations well-executed, we can start to scale up our write abstractions adding the support for writing data into intermediate data stores before writing it into ClickHouse asynchronously. We aim to prototype such an implementation with atleast one such backend.

#### Further iterations

With a backend-agnostic abstraction becoming the ingestion interface a client interacts with, there's various other use-cases that can be solved from within this abstraction. Some of them are:

- Zero-configuration data ingestion from multiple sources
- Dynamically enriching data from multiple sources
- Offloading data to long-term retention data stores

### Possible backend implementations

- Applications writing directly to ClickHouse
  - Application-local in-memory queueing/batching of data
  - Application-local persistent queueing/batching of data
- Non-local queueing/batching of data before eventually writing into ClickHouse
  - Managed cloud backends:
    - [Google PubSub](https://cloud.google.com/pubsub)
    - [AWS Kinesis](https://aws.amazon.com/kinesis/)
  - Self-managed backends:
    - [CHProxy](https://www.chproxy.org/)
    - [Kafka](https://kafka.apache.org/)
    - [RedPanda](https://redpanda.com/)
    - [Vector](https://vector.dev/)
    - [RabbitMQ](https://www.rabbitmq.com/)

### Additional complexity when using a non-local backend

- The need for running an additional process/sub-system that reads data from the concerned backend and writes it into ClickHouse efficiently and reliably.
- The additional hop across the backend also means that there might be potential delays in how soon this data lands into ClickHouse.

Though the points above describe additional complexity for an application, they can be treated as valid trade-off(s) assuming their need for data ingestion at scale.

### Comparing backends across multiple dimensions

| Dimension | CHProxy | Redis | Google PubSub | Apache Kafka |
|---|---|---|---|---|
| Operations | Trivial | Trivial | Managed | Non-trivial, complex |
| Data Retention | Non-durable | Non-durable | Durable | Durable |
| Performance | Good | Good | High | High |
| Data Streaming | None | Minimal | Good | Best |
| Suitable for self-managed environments | Trivial | Trivial | - | Complex |

## References

- [ClickHouse use-cases within Manage](https://gitlab.com/groups/gitlab-org/-/epics/7964)
- [List down all possible options for postgres to snowflake pipeline](https://gitlab.com/gitlab-data/gitlab.com-saas-data-pipeline/-/issues/13)
- [Design Spike for Snowplow For Data Event capture](https://gitlab.com/gitlab-data/analytics/-/issues/12397)
- [Audit Events Performance Limits](https://gitlab.com/gitlab-org/gitlab/-/issues/375545)
