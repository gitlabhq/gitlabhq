---
stage: enablement
group: Tenant Scale
description: 'Cells: Snippets'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: Snippets

Snippets will be scoped to an Organization. Initially it will not be possible to aggregate snippet collections across Organizations. See also [issue #416954](https://gitlab.com/gitlab-org/gitlab/-/issues/416954).

## 1. Definition

Two different types of snippets exist:

- [Project snippets](../../../../api/project_snippets.md). These snippets have URLs
  like `/<group>/<project>/-/snippets/123`
- [Personal snippets](../../../../user/snippets.md). These snippets have URLs like
  `/-/snippets/123`

Snippets are backed by a Git repository.

## 2. Data flow

## 3. Proposal

### 3.1. Scoped to an organization

Both project and personal snippets will be scoped to an Organization.

- Project snippets URLs will remain unchanged, as the URLs are routable.
- Personal snippets URLs will need to change to be `/-/organizations/<organization>/snippets/123`,
  so that the URL is routeable

Creation of snippets will also be scoped to a User's current Organization. Because of that, we recommend renaming `personal snippets` to `organization snippets` once the Organization is rolled out. A User can create many independent snippet collections across multiple Organizations.

## 4. Evaluation

Snippets are scoped to an Organization because Gitaly is confined to a Cell.

## 4.1. Pros

- No need to have clusterwide Gitaly.

## 4.2. Cons

- We will break [snippet discovery](/ee/user/snippets.md#discover-snippets).
- Snippet access may become subordinate to the visibility of the Organization.
