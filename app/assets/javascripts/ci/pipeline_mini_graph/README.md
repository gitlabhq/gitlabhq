# Pipeline Mini Graph

This documentation serves as a usage guide for the Pipeline Mini Graph. The Pipeline Mini Graph is used in various places throughout the platform to communicate to users the status of the relevant pipeline. Users are able to re-run jobs directly from the component or drilldown into said jobs and linked pipelines for further investigation.

The [architecture blueprint for the Pipeline Mini Graph](https://docs.gitlab.com/ee/architecture/blueprints/pipeline_mini_graph/) is available for more context. Furthermore, if you have questions about implementation of this component, please reach out to @gitlab-com/pipeline-authoring-group/frontend in your issue or MR. 

## Usage

This component can be instantiated by apps supporting either REST or GraphQL

### REST Structure

This is the current version of the component used by all apps in production. The parent component lives at `app/assets/javascripts/ci/pipeline_mini_graph/legacy_pipeline_mini_graph/legacy_pipeline_mini_graph.vue`. The legacy component needs all necessary pipeline data passed into it. [This data is fetched by apps via REST endpoint](https://docs.gitlab.com/ee/api/pipelines.html#get-a-single-pipeline). To use, import this component into your code and send the following props: 

| Name | Type | Required | Description |
| ---- | ---- | -------- | ----------- |
|`downstreamPipelines` | Array | false | pipelines triggered by current pipeline |
|`isMergeTrain` | Boolean | false | whether the pipeline is part of a merge train |
|`pipelinePath` | String | false | pipeline URL |
|`stages` | Array | true | stages of current pipeline |
|`updateDropdown` | Boolean | false | whether to fetch jobs when the dropdown is open |
|`upstreamPipeline` | Object | false | upstream pipeline which triggered current pipeline |

### GraphQL Structure

Note: This component currently exists behind a feature flag `ci_graphql_pipeline_mini_graph` and is under construction. 
The parent component lives at`app/assets/javascripts/ci/pipeline_mini_graph/pipeline_mini_graph.vue`. This instance of the pipeline mini graph has self-managed data. [We use GraphQL to query for pipeline data within the component](https://docs.gitlab.com/ee/api/graphql/reference/#pipeline). It needs only the fields necessary to query for the data. To use, import this component into your code and send the following props:

| Name | Type | Required | Description |
| ---- | ---- | -------- | ----------- |
|`fullPath` | String | true | full path of the project for the queries |
|`iid` | String | true | pipeline iid for the queries |
|`isMergeTrain` | Boolean | false | whether the pipeline is part of a merge train (under consideration) |
|`pipelineEtag` | String | true | etag for caching (under consideration) |
|`pollInterval` | Number | false | interval for polling updates |
