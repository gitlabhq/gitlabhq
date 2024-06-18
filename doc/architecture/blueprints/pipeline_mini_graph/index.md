---
status: ongoing
creation-date: "2024-05-27"
authors: [ "@bsandlin" ]
coach: "@ntepluhina"
approvers: [ "@dhershkovitch", "@marknuzzo" ]
owning-stage: "~devops::verify"
participating-stages: []
---

<!-- Blueprints often contain forward-looking statements -->
<!-- vale gitlab.FutureTense = NO -->

# Pipeline Mini Graph

This blueprint serves as living documentation for the Pipeline Mini Graph. The Pipeline Mini Graph is used in various places throughout the platform to communicate to users the status of the relevant pipeline. Users are able to re-run jobs directly from the component or drilldown into said jobs and linked pipelines for further investigation.

![Pipeline Mini Graph](img/pipeline_mini_graph.png)

## Motivation

While the Pipeline Mini Graph primarily functions via REST, we are updating the component to support GraphQL and subsequently migrating all instances of this component to GraphQL. This documentation will serve as the SSOT for this refactor. Developers have expressed difficulty contributing to this component as the two APIs co-exist, so we need to make this code easier to update while also supporting both REST and GraphQL. This refactor lives behind a feature flag called `ci_graphql_pipeline_mini_graph`.

### Goals

- Improved maintainability
- Backwards compatibility
- Improved query performance
- Deprecation of REST support

### Non-Goals

- Redesign of the Pipeline Mini Graph UI

## Proposal

To break down implementation, we are taking the following steps:

1. Separate the REST version and the GraphQL version of the component into 2 directories called `pipeline_mini_graph` and `legacy_pipeline_mini_graph`. This way, developers can contribute with more ease and we can easily remove the REST version once all apps are using GraphQL.
1. Finish updating the newer component to fully support GraphQL
1. Optimize GraphQL query structure to be more performant.
1. Roll out `ci_graphql_pipeline_mini_graph` to globally enable GraphQL instances of the component.

## Implementation Details

| Issue | Milestone | MR | Status |
| ----- | --------- | -- | ------ |
| [Move legacy files to new directory](https://gitlab.com/gitlab-org/gitlab/-/work_items/464375) | [17.1](https://gitlab.com/groups/gitlab-org/-/milestones/99#tab-issues) | [154625](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154625) | ✅ |
| [Move remaining legacy code](https://gitlab.com/gitlab-org/gitlab/-/work_items/464379) | [17.1](https://gitlab.com/groups/gitlab-org/-/milestones/99#tab-issues) |[154818](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154818) | ✅ |
| [Create README for PMG](https://gitlab.com/gitlab-org/gitlab/-/work_items/464632) | [17.1](https://gitlab.com/groups/gitlab-org/-/milestones/99#tab-issues) | [154964](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154964) | ✅ |
| [GraphQL Query Optimization](https://gitlab.com/gitlab-org/gitlab/-/issues/465309) | [17.1](https://gitlab.com/groups/gitlab-org/-/milestones/99#tab-issues) | [465309](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155129) | ✅ |
| [Dedicated component for downstream pipelines](https://gitlab.com/gitlab-org/gitlab/-/issues/466238) | [17.1](https://gitlab.com/groups/gitlab-org/-/milestones/99#tab-issues) | [155382](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155382) | ✅ |
| [Fetch Stage by ID](https://gitlab.com/gitlab-org/gitlab/-/issues/464100) | [17.2](https://gitlab.com/groups/gitlab-org/-/milestones/100#tab-issues) | TBD | In Dev |
| [Job Item](https://gitlab.com/gitlab-org/gitlab/-/issues/467278) | [17.2](https://gitlab.com/groups/gitlab-org/-/milestones/100#tab-issues) | TBD | Not Started |
| [Job Actions](https://gitlab.com/gitlab-org/gitlab/-/issues/467279) | [17.2](https://gitlab.com/groups/gitlab-org/-/milestones/100#tab-issues) | TBD | Not Started |
| [Rollout `ci_graphql_pipeline_mini_graph`](https://gitlab.com/gitlab-org/gitlab/-/issues/407818) | [17.2](https://gitlab.com/groups/gitlab-org/-/milestones/100#tab-issues) | TBD | Blocked |
| [Migrate MR PMG to GraphQL instance](https://gitlab.com/gitlab-org/gitlab/-/issues/419725) | [17.2](https://gitlab.com/groups/gitlab-org/-/milestones/100#tab-issues) | TBD | Blocked |
| [Migrate pipeline editor PMG to GraphQL instance](https://gitlab.com/gitlab-org/gitlab/-/issues/466275) | TBD | TBD | Blocked |
| [Migrate commit page PMG to GraphQL instance](https://gitlab.com/gitlab-org/gitlab/-/issues/466274) | TBD | TBD | Blocked |
| [Remove dead logic from PMG codebase](https://gitlab.com/gitlab-org/gitlab/-/issues/466277) | TBD | TBD | Blocked |

## Design Details

### REST Structure

#### File Structure

```plaintext
├── pipeline_mini_graph/
├── └── legacy_pipeline_mini_graph/
│       ├── legacy_job_item.vue
│       ├── legacy_linked_pipelines_mini_list.vue
│       ├── legacy_pipeline_mini_graph.vue
│       ├── legacy_pipeline_stage.vue
│       └── legacy_pipeline_stages.yml
```

All data for the legacy pipeline mini graph is passed into the REST instance of the component. This data comes from various API calls throughout different apps which use the component.

#### Properties

| Name | Type | Required | Description |
| ---- | ---- | -------- | ----------- |
|`downstreamPipelines` | Array | false | pipelines triggered by current pipeline |
|`isMergeTrain` | Boolean | false | whether the pipeline is part of a merge train |
|`pipelinePath` | String | false | pipeline URL |
|`stages` | Array | true | stages of current pipeline |
|`updateDropdown` | Boolean | false | whether to fetch jobs when the dropdown is open |
|`upstreamPipeline` | Object | false | upstream pipeline which triggered current pipeline |

### GraphQL Structure

The GraphQL instance of the pipeline mini graph has self-managed data.

#### Current File Structure

```plaintext
├── pipeline_mini_graph/
|   ├── job_item.vue
│   ├── linked_pipelines_mini_list.vue
│   ├── pipeline_mini_graph.vue
│   ├── pipeline_stage.vue
│   └── pipeline_stages.yml
├── ├── graphql/
│       ├── get_pipeline_stage_query.query.graphql
│       └── get_pipeline_stages_query.query.graphql
```

#### Current Properties

| Name | Type | Required | Description |
| --- | --- | --- | --- |
|`fullPath` | String | true | full path for the queries |
|`iid` | String | true | pipeline iid for the queries |
|`isMergeTrain` | Boolean | false | whether the pipeline is part of a merge train (under consideration) |
|`pipelineEtag` | String | true | etag for caching (under consideration) |
|`pollInterval` | Number | false | interval for polling updates |

#### Considerations

##### Properties

- `isMergeTrain`: This property is specific to the MR page and is used to display a message in the job dropdown to warn users that merge train jobs cannot be retried. This is an odd flow. Perhaps we should consider either having this data come from somewhere else within the pipeline mini graph, or living in the merge train widget itself. It is worth noting here that this boolean is not used for any other logic outside of displaying this message.

- `pipelineEtag`: Consider whether this data must be passed into the pipeline mini graph, or whether we can generate this within the component through a query.

##### Query Structure

Currently the approach is to use 2 queries in the parent file

- [getPipelineStages](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/ci/pipeline_mini_graph/graphql/queries/get_pipeline_stages.query.graphql?ref_type=heads): populates the stages of the current pipeline
- [getLinkedPipelines](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/ci/pipeline_details/graphql/queries/get_linked_pipelines.query.graphql?ref_type=heads): if there is an upstream pipeline or any downstream pipelines, this query will populate those

Another query called [getPipelineStage](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/ci/pipeline_mini_graph/graphql/queries/get_pipeline_stage.query.graphql?ref_type=heads) will be used to populate the dropdown when a stage icon is clicked. 

We need to consider whether this is the most performant way to query for the mini graph. 

Should pipeline stages and linked pipelines populate in 2 separate queries or is it okay to just have a single query for all icons and statuses in the mini graph to be displayed? Considerations below: 

- The reason this is currently split is because the upstream/downstream sections of the mini graph were added as a feature enhancement after the initial component already existed and they used to be a premium feature. Since we have restructured this to all exist as free, we should reconsider. 
- The pmg exists in several pipelines lists, so there will be up to 15 on a page rendering at a time.
- Since we have not implemented subscriptions, we are still using polling to update this component.
- If we merge two queries, do we hit maximum complexity or not?
- Loading time and the UI: What information do we want to render the fastest? Can we defer some information to load with the second query?

##### Directory Structure

There has been an [interest](https://gitlab.com/gitlab-org/gitlab/-/issues/345571) in more information from downstream pipelines. As such, we may want to consider rethinking `linked_pipelines_mini_list.vue` and having the downstream pipelines into their own file called `downstream_pipelines.vue` instead. The upstream pipeline could then be rendered with a simple `ci-icon`. 

## Future Improvements

- [GraphQL Subscriptions](https://gitlab.com/gitlab-org/gitlab/-/issues/406652)
- [Show downstream pipeline jobs](https://gitlab.com/gitlab-org/gitlab/-/issues/345571)
- Possible redesign
