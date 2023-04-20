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

### Goals

As ClickHouse has already been selected for use at GitLab, our main goal now is to ensure successful adoption of ClickHouse across GitLab. It is helpful to break down this goal according to the different phases of the product development workflow.

1. Plan: Make it easy for development teams to understand if ClickHouse is the right fit for their feature.
1. Develop and Test: Give teams the best practices and frameworks to develop ClickHouse-backed features.
1. Launch: Support ClickHouse-backed features for SaaS and self-managed.
1. Improve: Successfully scale our usage of ClickHouse.

### Non-Goals

## Proposals

The following are links to proposals in the form of blueprints that address technical challenges to using ClickHouse across a wide variety of features.

1. Scalable data ingestion pipeline.
    - How do we ingest large volumes of data from GitLab into ClickHouse either directly or by replicating existing data?
1. Supporting ClickHouse for self-managed installations.
    - For which use-cases and scales does it make sense to run ClickHouse for self-managed and what are the associated costs?
    - How can we best support self-managed installation of ClickHouse for different types/sizes of environments?
    - Consider using the [Opstrace ClickHouse operator](https://gitlab.com/gitlab-org/opstrace/opstrace/-/tree/main/clickhouse-operator) as the basis for a canonical distribution.
    - Consider exposing Clickhouse backend as [GitLab Plus](https://gitlab.com/groups/gitlab-org/-/epics/308) to combine benefits of using self-managed instance and GitLab-managed database.
    - Should we develop abstractions for querying and data ingestion to avoid requiring ClickHouse for small-scale installations?
1. Abstraction layer for features to leverage both ClickHouse or PostreSQL.
    - What are the benefits and tradeoffs? For example, how would this impact our automated migration and query testing?
1. Security recommendations and secure defaults for ClickHouse usage.

Note that we are still formulating proposals and will update the blueprint accordingly.

## Best Practices

Best practices and guidelines for developing performant and scalable features using ClickHouse are located in the [ClickHouse developer documentation](../../../development/database/clickhouse/index.md).

## Cost and maintenance analysis

ClickHouse components cost and maintenance analysis is located in the [ClickHouse Self-Managed component costs and maintenance requirements](self_managed_costs_and_requirements/index.md).
