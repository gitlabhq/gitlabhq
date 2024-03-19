---
status: proposed
creation-date: "2023-02-02"
authors: [ "@nhxnguyen" ]
coach: "@grzesiek"
approvers: [ "@dorrino", "@nhxnguyen" ]
owning-stage: "~devops::data stores"
participating-stages: ["~section::ops", "~section::dev"]
---

<!-- vale gitlab.FutureTense = NO -->

# ClickHouse Usage at GitLab

## Summary

[ClickHouse](https://clickhouse.com/) is an open-source column-oriented database management system. It can efficiently filter, aggregate, and sum across large numbers of rows. In FY23, GitLab selected ClickHouse as its standard data store for features with big data and insert-heavy requirements such as Observability and Analytics. This blueprint is a product of the [ClickHouse working group](https://handbook.gitlab.com/handbook/company/working-groups/clickhouse-datastore/). It serves as a high-level blueprint to ClickHouse adoption at GitLab and references other blueprints addressing specific ClickHouse-related technical challenges.

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

 A strategy for integrating ClickHouse into GitLab Dedicated has not begun. Leadership guidance has been to wait until there is clearer demand for ClickHouse backed features before prioritizing this.

### Product roadmap

#### FY24 H2 (past)

In FY24 Q2 we began working to integrate ClickHouse with GitLab.com to support multiple features under development (see [issue](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/34299)). We did not move forward attempting to integrate with self managed at this time due to the uncertain costs and management requirements for self-managed instances. This near-term implementation will be used to develop best practices and strategy to direct self-managed users. This will also constantly shape our recommendations for self-managed instances that want to onboard ClickHouse early. As of FY24 Q3 ClickHouse is available for use with GitLab.com.

#### FY25 H1 (current)

After we have formulated best practices of managing ClickHouse ourselves for GitLab.com, we will begin to offer supported recommendations for self-managed instances that want to run ClickHouse themselves. During this phase we will allow users to "Bring your own ClickHouse" similar to our [approach for Elasticsearch](../../../integration/advanced_search/elasticsearch.md#install-elasticsearch). For the features that require ClickHouse for optimal usage (Value Streams Dashboard, [Product Analytics](https://gitlab.com/groups/gitlab-org/-/epics/8921)), this will be the initial go-to-market action. Notably, the Observability team has made the decision to support self-managed users via GitLab Cloud Connector instead of following this approach.

#### Long-term

We will work towards a packaged reference version of ClickHouse capable of being easily managed with minimal cost increases for self-managed users. We should be able to reliably instruct users on the management of ClickHouse and provide accurate costs for usage. This will mean any feature could depend on ClickHouse without decreasing end-user exposure.

## Best Practices

Best practices and guidelines for developing performant, secure, and scalable features using ClickHouse are located in the [ClickHouse developer documentation](../../../development/database/clickhouse/index.md).

## Cost and maintenance analysis

ClickHouse components cost and maintenance analysis is located in the [ClickHouse Self-Managed component costs and maintenance requirements](self_managed_costs_and_requirements/index.md).
