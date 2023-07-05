---
status: proposed
creation-date: "2023-02-02"
authors: [ "@nhxnguyen" ]
coach: "@grzesiek"
approvers: [ "@dorrino", "@nhxnguyen" ]
owning-stage: "~devops::data_stores"
participating-stages: ["~section::ops", "~section::dev"]
---

<!-- vale gitlab.FutureTense = NO -->

# ClickHouse Usage at GitLab

## Summary

[ClickHouse](https://clickhouse.com/) is an open-source column-oriented database management system. It can efficiently filter, aggregate, and sum across large numbers of rows. In FY23, GitLab selected ClickHouse as its standard data store for features with big data and insert-heavy requirements such as Observability and Analytics. This blueprint is a product of the [ClickHouse working group](https://about.gitlab.com/company/team/structure/working-groups/clickhouse-datastore/). It serves as a high-level blueprint to ClickHouse adoption at GitLab and references other blueprints addressing specific ClickHouse-related technical challenges.

## Motivation

In FY23-Q2, the Monitor:Observability team developed and shipped a [ClickHouse data platform](https://gitlab.com/groups/gitlab-org/-/epics/7772) to store and query data for Error Tracking and other observability features. Other teams have also begun to incorporate ClickHouse into their current or planned architectures. Given the growing interest in ClickHouse across product development teams, it is important to have a cohesive strategy for developing features using ClickHouse. This will allow teams to more efficiently leverage ClickHouse and ensure that we can maintain and support this functionality effectively for SaaS and self-managed customers.

### Use Cases

Many product teams at GitLab are considering ClickHouse when developing new features and to improve performance of existing features.

During the start of the ClickHouse working group, we [documented existing and potential use cases](https://gitlab.com/groups/gitlab-com/-/epics/2075#use-cases) and found that there was interest in ClickHouse from teams across all DevSecOps stage groups.

### Goals

As ClickHouse has already been selected for use at GitLab, our main goal now is to ensure successful adoption of ClickHouse across GitLab. It is helpful to break down this goal according to the different phases of the product development workflow.

1. Plan: Make it easy for development teams to understand if ClickHouse is the right fit for their feature.
1. Develop and Test: Give teams the best practices and frameworks to develop ClickHouse-backed features.
1. Launch: Support ClickHouse-backed features for SaaS and self-managed.
1. Improve: Successfully scale our usage of ClickHouse.

### Non-goals

ClickHouse will not be packaged by default with self-managed GitLab, due to uncertain need, complexity, and lack of operational experience. We will still work to find the best possible way to enable users to use ClickHouse themselves if they desire, but it will not be on by default. [ClickHouse maintenance and cost](self_managed_costs_and_requirements/index.md) investigations revealed an uncertain cost impact to smaller instances, and at this time unknown nuance to managing ClickHouse. This means features that depend only on ClickHouse will not be available out of the box for self-managed users (as of end of 2022, the majority of revenue comes from self-managed), so new features researching the use of ClickHouse should be aware of the potential impacts to user adoption in the near-term, until a solution is viable.

## Proposals

The following are links to proposals in the form of blueprints that address technical challenges to using ClickHouse across a wide variety of features.

1. [Scalable data ingestion pipeline](../clickhouse_ingestion_pipeline/index.md).
    - How do we ingest large volumes of data from GitLab into ClickHouse either directly or by replicating existing data?
1. [Abstraction layer](../clickhouse_read_abstraction_layer/index.md) for features to leverage both ClickHouse and PostgreSQL.
    - What are the benefits and tradeoffs? For example, how would this impact our automated migration and query testing?

### Product roadmap

#### Near-term

In the next 3 months (FY24 Q2) ClickHouse will be implemented by default only for SaaS on GitLab.com or manual enablement for self-managed instances. This is due to the uncertain costs and management requirements for self-managed instances. This near-term implementation will be used to develop best practices and strategy to direct self-managed users. This will also constantly shape our recommendations for self-managed instances that want to onboard ClickHouse early.

#### Mid-term

After we have formulated best practices of managing ClickHouse ourselves for GitLab.com, the plan for 3-9 months (FY24 2H) will be to offer supported recommendations for self-managed instances that want to run ClickHouse themselves or potentially to a ClickHouse cluster/VM we would manage for users. One proposal for self-managed users is to [create a proxy or abstraction layer](https://gitlab.com/groups/gitlab-org/-/epics/308) that would allow users to connect their self-managed instance to SaaS without additional effort. Another option would be to allow users to "Bring your own ClickHouse" similar to our [approach for Elasticsearch](../../../integration/advanced_search/elasticsearch.md#install-elasticsearch). For the features that require ClickHouse for optimal usage (Value Streams Dashboard, [Product Analytics](https://gitlab.com/groups/gitlab-org/-/epics/8921) and Observability), this will be the initial go-to-market action.

#### Long-term

We will work towards a packaged reference version of ClickHouse capable of being easily managed with minimal cost increases for self-managed users. We should be able to reliably instruct users on the management of ClickHouse and provide accurate costs for usage. This will mean any feature could depend on ClickHouse without decreasing end-user exposure.

## Best Practices

Best practices and guidelines for developing performant, secure, and scalable features using ClickHouse are located in the [ClickHouse developer documentation](../../../development/database/clickhouse/index.md).

## Cost and maintenance analysis

ClickHouse components cost and maintenance analysis is located in the [ClickHouse Self-Managed component costs and maintenance requirements](self_managed_costs_and_requirements/index.md).
