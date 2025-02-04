---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Troubleshooting frontend development issues
---

Running into a problem? Maybe this will help ¯\＿(ツ)＿/¯.

## Troubleshooting issues

### This guide doesn't contain the issue you ran into

If you run into a Frontend development issue that is not in this guide, consider updating this guide with your issue and possible remedies. This way future adventurers can face these dragons with more success, being armed with your experience and knowledge.

## Testing issues

### ``Property or method `nodeType` is not defined`` but you're not using `nodeType` anywhere

This issue can happen in Vue component tests, when an expectation fails, but there is an error thrown when
Jest tries to pretty print the diff in the console. It's been noted that using `toEqual` with an array as a
property might also be a contributing factor.

See [this video](https://youtu.be/-BkEhghP-kM) for an in-depth overview and investigation.

**Remedy - Try cloning the object that has Vue watchers**

```patch
- expect(wrapper.findComponent(ChildComponent).props()).toEqual(...);
+ expect(cloneDeep(wrapper.findComponent(ChildComponent).props())).toEqual(...)
```

**Remedy - Try using `toMatchObject` instead of `toEqual`**

```patch
- expect(wrapper.findComponent(ChildComponent).props()).toEqual(...);
+ expect(wrapper.findComponent(ChildComponent).props()).toMatchObject(...);
```

`toMatchObject` actually changes the nature of the assertion and won't fail if some items are **missing** from the expectation.

### Script issues

## `core-js` errors when running scripts within the GitLab repository

The following command assumes you've set up the GitLab repository in the
`~/workspace/gdk` directory. When running scripts within the GitLab repository,
such as code transformations, you might run into issues with `core-js` like this:

```shell
~/workspace/gdk/gitlab/node_modules/core-js/modules/es.global-this.js:7
$({
^
TypeError: $ is not a function
    at Object.<anonymous> (~/workspace/gdk/gitlab/node_modules/core-js/modules/es.global-this.js:6:1)
    at Module._compile (internal/modules/cjs/loader.js:1063:30)
    at Module._compile (~/workspace/gdk/gitlab/node_modules/pirates/lib/index.js:99:24)
    at Module._extensions..js (internal/modules/cjs/loader.js:1092:10)
    at Object.newLoader [as .js] (~/workspace/gdk/gitlab/node_modules/pirates/lib/index.js:104:7)
    at Module.load (internal/modules/cjs/loader.js:928:32)
    at Function.Module._load (internal/modules/cjs/loader.js:769:14)
    at Module.require (internal/modules/cjs/loader.js:952:19)
    at require (internal/modules/cjs/helpers.js:88:18)
    at Object.<anonymous> (~/workspace/gdk/gitlab/node_modules/core-js/modules/esnext.global-this.js:2:1)
```

**Remedy - Try moving the script into a separate repository and point to it to files in the GitLab repository**

## Using Vue component issues

### When rendering a component that uses GlFilteredSearch and the component or its parent uses Vue Apollo

When trying to render our component GlFilteredSearch, you might get an error in the component's `provide` function:

`cannot read suggestionsListClass of undefined`

Currently, `vue-apollo` tries to [manually call a component's `provide()` in the `beforeCreate` part](https://github.com/vuejs/vue-apollo/blob/35e27ec398d844869e1bbbde73c6068b8aabe78a/packages/vue-apollo/src/mixin.js#L149) of the component lifecycle. This means that when a `provide()` references props, which aren't actually setup until after `created`, it will blow up.

See this [closed MR](https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/2019#note_514671251) for more context.

**Remedy - try providing `apolloProvider` to the top-level Vue instance options**

VueApollo will skip manually running `provide()` if it sees that an `apolloProvider` is provided in the `$options`.

```patch
  new Vue(
    el,
+   apolloProvider: {},
    render(h) {
      return h(App);
    },
  );
```

## Troubleshooting Apollo Client issues

### console errors when writing to cache

If you see errors like `Missing field 'descriptionHtml' while writing result` , it means we are not adhering to the GraphQL response structure while writing to the Apollo client cache. It seems you're encountering a GraphQL error ("Missing field 'description'") within your web application, likely related to how you're handling Apollo Client's cache and data updates. The error stack trace provides clues about the specific parts of the Apollo Client code where the problem occurs.

**The Core Issue:**

The error "Missing field 'description'" indicates that your GraphQL query expects a field named "description" in the response, but the data you're receiving from your backend (or how it's being processed by Apollo Client) is missing that field. This is causing Apollo Client's cache to fail when it tries to update the store with the incomplete data.

To debug this , follow the below steps

1. Open the error stack developer console

```shell
Missing field 'description' while writing result {
  "type": "DESCRIPTION",
  "lastEditedAt": null,
  "lastEditedBy": null,
  "taskCompletionStatus": null,
  "__typename": "WorkItemWidgetDescription"
}
```

1. Double-check your GraphQL query to ensure it's requesting the "description" field. If it's not included, Apollo Client won't be able to find it in the response.
1. The backend might not be returning the "description" field in the response for the "WorkItemWidgetDescription" type. Verify that your backend API is correctly sending the data as expected.
1. Use the `cache.readQuery` method to inspect the contents of the Apollo Client cache. Verify that the "description" field is present in the cached data for the relevant query
1. Open the error stack trace suggesting that the issue might be related to how Apollo Client is writing data to its cache. It's possible that the cache is not being updated correctly, leading to missing fields
1. Add console logs within your Apollo Client code (e.g., before and after writing to the cache) to track the data being processed and identify where the "description" field might be missing.

**Solution**

Ensure that you're using the correct `writeQuery` or `writeFragment` methods in your Apollo Client code to update the cache with the complete data, including the "description" field

You should be able to see the method in the stack trace where this is originating from. Make sure you add the "description" field when writing to the cache

### Queries not being cached with the same variables

Apollo GraphQL queries may not be cached in several scenarios:

1. Cache Misses or Partial Caches/Query Invalidation or Changes:
If the query only returns partial data or there’s a cache miss (when part of the requested data isn’t in the cache), Apollo might not be able to cache the result effectively.

If data related to a query has been invalidated or updated, the cache might not have valid information. For example:

When using mutations, the cache might not automatically update unless you configure `refetchQueries` or use a manual cache update after the mutation.

For example : in the first query you have a couple of fields that were not requested in the subsequent query

```graphql
query workItemTreeQuery($id: WorkItemID!, $pageSize: Int = 100, $endCursor: String) {
  workItem(id: $id) {
    namespace {
      id
    }
    userPermissions {
      deleteWorkItem
      updateWorkItem
    }
  }
}
```

```patch
query workItemTreeQuery($id: WorkItemID!, $pageSize: Int = 100, $endCursor: String) {
  workItem(id: $id) {
    namespace {
      id
+     fullPath
    }
    userPermissions {
      deleteWorkItem
      updateWorkItem
+     adminParentLink
+     setWorkItemMetadata
+     createNote
+     adminWorkItemLink
    }
  }
}
```

1. `fetchPolicy` Settings:
Apollo Client uses a fetchPolicy to control how queries interact with the cache. Depending on the policy, the query may bypass caching entirely if the fetchPolicy is `no-cache`. This policy ensures that no part of the query is written to the cache. Each query directly fetches data from the server and doesn't store any results in the cache and hence multiple queries are being fetched

1. When the same query is fired from different Apollo Client instances. It may be that the clients firing the two queries are from different clients.

1. Missing `id` or `__typename`:
Apollo Client uses `id` and `__typename` to uniquely identify entities and cache them. If these fields are missing from your query response, Apollo may not be able to cache the result properly.

1. Complex or Nested Queries:
Some queries might be too complex or involve nested queries that Apollo Client might struggle to cache correctly. This can happen if the structure of the data returned doesn’t map cleanly to the cache schema, requiring manual cache management.

1. Pagination Queries:
For queries involving pagination, like those using fetchMore, Apollo might not cache results properly unless the cache is explicitly updated.

In all of these cases, you may need to configure Apollo’s cache policies or manually update the cache to handle query caching effectively.
