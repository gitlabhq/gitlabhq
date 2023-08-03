---
stage: enablement
group: Tenant Scale
description: 'Cells: GraphQL'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: GraphQL

GitLab extensively uses GraphQL to perform efficient data query operations.
GraphQL due to it's nature is not directly routable.
The way GitLab uses it calls the `/api/graphql` endpoint, and only the query or mutation of the body request might define where the data can be accessed.

## 1. Definition

## 2. Data flow

## 3. Proposal

There are at least two main ways to implement GraphQL in a Cells architecture.

### 3.1. GraphQL routable by endpoint

Change `/api/graphql` to `/api/organization/<organization>/graphql`.

- This breaks all existing usages of `/api/graphql` endpoint because the API URI is changed.

### 3.2. GraphQL routable by body

As part of router parse GraphQL body to find a routable entity, like `project`.

- This still makes the GraphQL query be executed only in context of a given Cell and not allowing the data to be merged.

```json
# Good example
{
  project(fullPath:"gitlab-org/gitlab") {
    id
    description
  }
}

# Bad example, since Merge Request is not routable
{
  mergeRequest(id: 1111) {
    iid
    description
  }
}
```

### 3.3. Merging GraphQL Proxy

Implement as part of router GraphQL Proxy which can parse body and merge results from many Cells.

- This might make pagination hard to achieve, or we might assume that we execute many queries of which results are merged across all Cells.

```json
{
  project(fullPath:"gitlab-org/gitlab"){
    id, description
  }
  group(fullPath:"gitlab-com") {
    id, description
  }
}
```

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
