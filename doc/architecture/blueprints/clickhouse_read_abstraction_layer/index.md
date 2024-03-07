---
status: proposed
creation-date: "2023-02-23"
authors: [ "@mikolaj_wawrzyniak", "@jdrpereira", "@pskorupa" ]
coach: "@DylanGriffith"
approvers: [ "@nhxnguyen" ]
owning-stage: "~workinggroup::clickhouse"
participating-stages: []
---

# Consider an abstraction layer to interact with ClickHouse or alternatives

## Table of Contents

- [Summary](#summary)
- [Motivation](#motivation)
- [Goals](#goals)
- [Non-goals](#non-goals)
- [Possible solutions](#possible-solutions)
  - [Recommended approach](#recommended-approach)
  - [Overview of open source tools](#overview-of-open-source-tools)
- [Open Questions](#open-questions)

## Summary

Provide a solution standardizing read access to ClickHouse or its alternatives for GitLab installations that will not opt-in to install ClickHouse. After analyzing different [open-source tools](#overview-of-open-source-tools) and weighing them against an option to [build a solution internally](#recommended-approach). The current recommended approach proposes to use dedicated database-level drivers to connect to each data source. Additionally, it proposes the usage of [repository pattern](https://martinfowler.com/eaaCatalog/repository.html) to confine optionally database availability complexity to a single application layer.

## Motivation

ClickHouse requires significant resources to be run, and smaller installations of GitLab might not get a return from investment with provided performance improvement. That creates a risk that ClickHouse might not be globally available for all installations and features might need to alternate between different data stores available. Out of all [present & future ClickHouse use cases](https://gitlab.com/groups/gitlab-com/-/epics/2075) that have been already proposed as part of the working group 7 out of 10 uses data stores different than ClickHouse. Considering that context it is important to
support those use cases in their effort to adopt ClickHouse by providing them with tools and guidelines that will standardize interactions with available data stores.

The proposed solution can take different forms from stand-alone tooling
offering a unified interface for interactions with underlying data stores, to a set of libraries supporting each of the data stored individually backed by implementation guidelines that will describe rules and limitations placed around data stores interactions, and drawing borders of encapsulation.

## Goals

- Limit the impact of optionally available data stores on the overall GitLab application codebase to [single abstraction layer](../../../development/reusing_abstractions.md#abstractions)
- Support all data store specific features
- Support communication for satellite services of the main GitLab application

## Non-goals

- This proposal does not directly consider write communication with database, as this is a subject of [complementary effort](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111148)
- This proposal does not directly consider schema changes and data migration challenges

Despite above points being non goals, it is acknowledge that they might impose some alterations to final solution which is expressed at the end of this document in the [Open questions](#open-questions) section.

## Possible Solutions

High-level goals described in the previous paragraph can be achieved by both in-house-built solutions as well as by adopting open-source tools.
The following sections will take a closer look into both of those avenues

### Recommended approach

In the spirit of MVC and iteration, it is proposed to start with a solution that would rely on drivers that directly interact
with corresponding data stores, like ActiveRecord for Ruby. For this solution to be able to achieve goals set for
this exit criteria and help mitigate the issue listed in the _Motivation_ section of this document, such drivers need to be supported
by a set of development guidelines enforced with static code analysis.

Such a solution was selected as preferred upon receiving feedback from different members of the working group concerned
about the risk of limitations that might be imposed by open-source tools, preventing groups from taking advantage of ClickHouse
features to their fullest. Members collaborating around working group criteria presented in this document, agree that
concerns around limitations could be mitigated by building a comprehensive set of prototypes, however time and effort
required to achieve that surpass the limits of this working group. It is also important to notice that ClickHouse adoption
is in an exploratory stage, and groups might not being even able to state what are their requirements just yet.

#### Proposed drivers

Following ClickHouse documentation there are the following drivers for Ruby and Go

##### Ruby

1. [ClickHouse Ruby driver](https://github.com/shlima/click_house) - Previously selected for use in GitLab as part of the Observability grup's research (see: [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/358158))
1. [Clickhouse::Activerecord](https://github.com/PNixx/clickhouse-activerecord)

##### Go

1. [ClickHouse/clickhouse-go](https://github.com/ClickHouse/clickhouse-go) - Official SQL database client.
1. [uptrace/go-clickhouse](https://clickhouse.uptrace.dev/) - Alternative client.

##### Proposed client architecture

To keep the codebase well organized and limit coupling to any specific database engine it is important to encapsulate
interactions, including querying data to a single application layer, that would present its interface to layers above in
similar vain to [ActiveRecord interface propagation through abstraction layers](../../../development/reusing_abstractions.md)

Keeping underlying database engines encapsulated makes the recommended solution a good two-way door decision that
keeps the opportunity to introduce other tools later on, while giving groups time to explore and understand their use cases.

At the lowest abstraction layer, it can be expected that there will be a family of classes directly interacting with the ClickHouse driver, those classes
following MVC pattern implemented by Rails should be classified as _Models_.

Models-level abstraction builds well into existing patterns and guidelines but unfortunately does not solve the challenge of the optional availability of the ClickHouse database engine for self-managed instances. It is required to design a dedicated entity that will house responsibility of selecting best database to serve business logic request.
From the already mentioned existing abstraction [guidelines](../../../development/reusing_abstractions.md)  `Finders` seems to be the closest to the given requirements, due to the fact that `Finders` encapsulate database specific interaction behind their own public API, hiding database vendors detail from all layers above them.

However, they are closely coupled to `ActiveRecord` ORM framework, and are bound by existing GitLab convention to return `ActiveRecord::Relation` objects, that might be used to compose even more complex queries. That coupling makes `Finders` unfit to deal with the optional availability of ClickHouse because returned data might come from two different databases, and might not be compatible with each other.

With all that above in mind it might be worth considering adding a new entity into the codebase that would exist on a similar level of abstraction as `Finders` yet it would be required to return an `Array` of data objects instead.

Required level of isolation can be achieved with usage of a [repository pattern](https://martinfowler.com/eaaCatalog/repository.html). The repository pattern is designed to separates business / domain logic from data access concerns, which is exactly what this proposal is looking for.
What is more the repository pattern does not limits operations performed on underlying databases allowing for full utilization of their features.

To implement the repository pattern following things needs to be created:

1. A **strategy** for each of supported databases, for example: `MyAwesomeFeature::Repository::Strategies::ClickHouseStrategy` and `MyAwesomeFeature::Repository::Strategies::PostgreSQLStrategy`. Strategies are responsible for implementing communication with underlying database ie: composing queries
1. A **repository** that is responsible for exposing high level interface to interact with database using one of available strategies selected with some predefined criteria ie: database availability. Strategies used by single repository must share the same public interface so they can be used interchangeable
1. A **Plain Old Ruby Object(PORO) Model** that represents data in business logic implemented by application layers using repository. It have to be database agnostic

It is important to notice that the repository pattern based solution has already been implemented by Observability group (kudos to: @ahegyi, @splattael and @brodock). [`ErrorTracking::ErrorRepository`](https://gitlab.com/gitlab-org/gitlab/-/blob/1070c008b9e72626e25296480f82f2ee2b93f847/lib/gitlab/error_tracking/error_repository.rb) is being used to support migration of error tracking features from PostgreSQL to ClickHouse (integrated via API), and uses feature flag toggle as database selection criteria, that is great example of optional availability of database.

`ErrorRepository` is using two strategies:

1. [`OpenApiStrategy`](https://gitlab.com/gitlab-org/gitlab/-/blob/d0bdc8370ef17891fd718a4578e41fef97cf065d/lib/gitlab/error_tracking/error_repository/open_api_strategy.rb) to interact with ClickHouse using API proxy entity
1. [`ActiveRecordStrategy`](https://gitlab.com/gitlab-org/gitlab/-/blob/d0bdc8370ef17891fd718a4578e41fef97cf065d/lib/gitlab/error_tracking/error_repository/active_record_strategy.rb) to interact with PostgreSQL using `ActiveRecord` framework

Each of those strategies return data back to abstraction layers above using following PORO Models:

1. [`Gitlab::ErrorTracking::Error`](https://gitlab.com/gitlab-org/gitlab/-/blob/a8ea29d51ff23cd8f5b467de9063b64716c81879/lib/gitlab/error_tracking/error.rb)
1. [`Gitlab::ErrorTracking::DetailedError`](https://gitlab.com/gitlab-org/gitlab/-/blob/a8ea29d51ff23cd8f5b467de9063b64716c81879/lib/gitlab/error_tracking/detailed_error.rb)

Additionally `ErrorRepository` is great example of remarkable flexibility offered by the repository pattern in terms of supported types of data stores, allowing to integrate solutions as different as a library and external service API under single unified interface. That example presents opportunity that the repository pattern in the future might be expanded beyond needs of ClickHouse and PostgreSQL when some use case would call for it.

Following [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85907/diffs) documents changes done by observability group in order to migrate from using current GitLab architecture based on ActiveRecord Models, Services and Finders to the repository pattern.

##### Possible ways to enforce client architecture

It is not enough to propose a client-side architecture for it to fully be established as common practice it needs
to be automatically enforced, reducing the risk of developers unconsciously going against it. There are multiple ways to
introduce automated verification of repository pattern implementation including:

1. Utilize `ActiveRecord` query subscribers in a similar way to[Database::PreventCrossJoins](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/database/prevent_cross_joins.rb) in order to detect queries to ClickHouse executed outside of _Strategies_
1. Expanding [`CodeReuse`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/rubocop/cop/code_reuse) rubocop rules to flag all usage of ClickHouse driver outside of _Strategies_
1. Create rubocop rule that detects calls to utility method that checks the presence of ClickHouse instance (ie: `CurrentSettings.click_house_enabled?`) that are being made outside of _Repositories_

At this development stage, authors see all of the listed options as viable and promising, therefore a decision about which ones to use would be deferred to the moment when the first repository pattern implementation for ClickHouse will emerge.

### Overview of open-source tools

In this section authors provide an overview of existing 3rd party open-source solutions that were considered as alternative approaches to achieve stated goal, but was not selected as recommended approach.

#### Evaluation criteria

##### 1. License (MUST HAVE)

1. Solutions must be open source under an [acceptable license](https://handbook.gitlab.com/handbook/engineering/open-source/#acceptable-licenses).

##### 2. Support for different data stores (MUST HAVE)

1. It focuses on the fact whether the proposed abstraction layer can support both ClickHouse and PostgreSQL (must have)
1. Additional consideration might be if more than the two must-have storages are supported
1. The solution must support the [minimum required versions](../../../install/requirements.md#postgresql-requirements) for PostgreSQL

##### 3. Protocol compatibility

Every abstraction layer comes at the cost of limited API compared to direct access to the tool. This exit criterion is trying to bring understanding to the degree of trade-off being made on limiting tools API for the sake of a common abstraction.

1. List what read operations can be done via PostgreSQL and ClickHouse (`selects`, `joins`, `group by`, `order by`, `union` etc)
1. List what operations can be done with the proposed abstraction layer, how complicated it is to do such operations, and whether are there any performance concerns when compared to running operations natively
1. Does it still allow for direct access to a data source in case the required operation is not supported by the abstraction layer, eg: `ActiveRecord` allows for raw SQL strings to be run with `#execute`

##### 4. Operational effort

1. Deployment process: how complex is it? Is the proposed tool a library tool that is being added into the stack, or does it require additional services to be deployed independently along the GitLab system. What deployment types does the tool support (Kubernetes/VMs, SaaS/self-managed, supported OS, cloud providers). Does it support offline installation.
1. How many hardware resources does it need to operate
1. Does it require complex monitoring and operations to assure stable and performant services
1. Matured maintenance process and documentation around it: upgrades, backup and restore, scaling
1. High-availability support. Does the tool have documentation how to build HA cluster and perform failovers for self-managed? Does the tool support zero-downtime upgrade?
1. FIPS and FedRAMP compliance
1. Replication process and how the new tool would fit in GitLab Geo.

##### 5. Developer experience

1. Solutions must have well-structured, clear, and thoroughly documented APIs to ease adoption and reduce the learning curve.

##### 6. Maturity (nice to have)

1. How long does the solution exist? Is it used often? Does it have a stable community? If the license permits forking tool is also a considerable option

##### 7. Tech fit

1. Is the solution written in one of the programming languages we use at GitLab so that we can more easily contribute with bug fixes and new features?

##### 8. Interoperability (Must have)

1. Can the solution support both the main GitLab application written in Ruby on Rails also satellite services like container registry that might be written in Go

#### Open - Source solutions

##### 1. [Cube.dev](https://cube.dev/)

**Evaluation**

1. License
   Apache 2.0 + MIT ✅
1. Support for different data stores
   Yes ✅
1. Protocol compatibility
   It uses OLAP theory concepts to aggregate data. This might be useful in some use cases like aggregating usage metrics, but not in others. It has APIs for both SQL queries and their own query format.
1. Operational effort
   Separate service to be deployed using Docker or k8s. Uses Redis as a cache and data structure store.
1. Developer experience
   Good [documentation](https://cube.dev/docs/product/introduction)
1. Maturity
   Headless BI tools themselves are a fairly new idea, but Cube.js seems to be the leading open-source solution in this space.
   The Analytics section uses it internally for our Product Analytics stack.
1. Tech fit
   Uses REST and GraphQL APIs. It has its own query and data schema formats, but they are well-documented. Data definitions in either YAML or JavaScript.

**Comment**

The solution is already being used as a read interface for ClickHouse by ~"group::product analytics",
to gather first hand experience there was a conversation held with @mwoolf with key conclusions being:

1. ClickHouse driver for cube.dev is community-sourced, and it does not have a maintainer as of now, which means there is no active development. It is a small and rather simple repository that should work at least until a new major version of ClickHouse will arrive with some breaking changes
1. Cube.dev is written in Type Script and JavaScript which are part of GitLab technical stack, and there are engineers here with expertise in them, however Cube.dev is expected to be mostly used by backend developers, which does not have that much experience in mentioned technologies
1. Abstraction layer for simple SQL works, based on JSON will build correct query depending on the backend
1. Data store-specific functions (like window funnel ClickHouse) are not being translated to other engines, which requires additional cube schemas to be built to represent the same data.
1. Performance so far was not an issue both on local dev and on AWS VPS millions of rows import load testing
1. It expose postgres SQL like interface for most engines, but not for ClickHouse unfortunately so for sake of working group use case JSON API might be more feasible
1. Cube.dev can automatically generate schemas on the fly, which can be used conditionally in the runtime handling optional components like ClickHouse

There is also a [recording](https://youtu.be/iBPTCrvOBBs) of that conversation available.

##### 2. [ClickHouse FDW](https://github.com/ildus/clickhouse_fdw)

**Evaluation**

A ClickHouse Foreign Data Wrapper for PostgreSQL. It allows ClickHouse tables to be queried as if they were stored in PostgreSQL.
Could be a viable option to easily introduce ClickHouse as a drop-in replacement when Postgres stops scaling.

1. License
   Apache 2.0 ✅
1. Support for different data stores
   Yes, by calling ClickHouse through a PostgreSQL instance. ✅
1. Protocol compatibility
   Supports SELECT, INSERT statements at a first glance. Not sure about joins. Allows for raw SQL by definition.
1. Operational effort
   1. A PostgreSQL extension. Requires some mapping between the two DBs.
   1. Might have adversary impact on PostgreSQL performance, when execution would wait for response from ClickHouse waisting CPU cycles on waiting
   1. Require exposing and managing connection between deployments of PostgreSQL and ClickHouse
1. Developer experience
   TBD
1. Maturity
   It's been around for a few years and is listed in ClickHouse docs, but doesn't seem to be widely used.
1. Tech fit
   Raw SQL statements.

**Comment**

##### 3. [Clickhouse::Activerecord](https://github.com/PNixx/clickhouse-activerecord)

**Evaluation**

1. License
   MIT License ✅
1. Support for different data stores
   Yes, in the sense that it provides a Clickhouse adapter for ActiveRecord in the application layer so that it can be used to query along PostgreSQL. ✅
1. Protocol compatibility
   Not sure about joins - no examples.
1. Operational effort
   Ruby on Rails library tool - ORM interface in a form of an ActiveRecord adapter.
1. Developer experience
   Easy to work with for developers familiar with Rails.
1. Maturity
   Has been around for a few years, but repo activity is scarce (not a bad thing by itself, however).
1. Tech fit
   Rails library, so yes.

**Comment**

##### 4. [Metriql](https://metriql.com/)

**Evaluation**

A headless BI solution using DBT to source data. Similar to Cube.dev in terms of defining metrics from data and transforming them with aggregations.
The authors explain the differences between Metriql and other BI tools like Cube.js in this FAQ entry.

1. License
   Apache 2.0 ✅
1. Support for different data stores
   Uses DBT to read from data sources, so CH and PostgreSQL are possible.
1. Protocol compatibility
   It uses OLAP theory concepts to aggregate data. It does allow for impromptu SQL queries through a REST API.
1. Operational effort
   It's a separate service to deploy and requires DBT.
1. Developer experience
   I assume it requires DBT knowledge to set up and use. It has a fairly simple REST API documented here.
1. Maturity
   First release May 2021, but repo activity is scarce (not a bad thing by itself).
1. Tech fit
   Connects with BI tools through a REST API or JDBC Adapter. Allows querying using SQL or MQL (which is a SQL flavor/subset).

**Comment**

##### 5. Notable rejected 3rd party solutions

ETL only solutions like Airflow and Meltano, as well as visualization tools like Tableau and Apache Superset, were excluded from the prospect list as they are usually clearly outside our criteria.

**[pg2ch](https://github.com/mkabilov/pg2ch)**
PostgreSQL to ClickHouse mirroring using logical replication.
Repo archived; explicitly labeled not for production use. Logical replication might not be performant enough at our scale - we don't use it in our PostgreSQL DBs because of performance concerns.

**Looker**
BI tooling.
Closed-source; proprietary.

**[Hasura](https://github.com/hasura/graphql-engine)**
GraphQL interface for database sources.
No ClickHouse support yet.

**[dbt Server](https://github.com/dbt-labs/dbt-server)**
HTTP API for dbt. MariaDB Business Source License (BSL) ❌

### Open questions

1. This proposal main focus is read interface, however depending on outcome of [complementary effort](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111148) that focus on write interface similar concerns around optional availability might be applicable to write interaction. In case if ingestion pipeline would not resolve optional availability challenges for write interface it might be considerable to include write interactions into repository pattern implementation proposed in this document.
1. Concerns around ClickHouse schema changes and data migrations is not covered by any existing working group criteria, even though solving this challenges as a whole is outside of the scope of this document it is prudent to raise awareness that some alterations to proposed repository pattern based implementation might be required in order to support schema changes.
