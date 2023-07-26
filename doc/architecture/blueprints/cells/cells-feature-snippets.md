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

- [Project snippets](../../../api/project_snippets.md)
- [Personal snippets](../../../user/snippets.md)

Snippets are backed by a Git repository.

## 2. Data flow

## 3. Proposal

- Both project and personal snippets will be scoped to an Organization.
- Creation of snippets will also be scoped to a User's current Organization.
- A User can create many independent snippet collections across multiple Organizations.
- Snippets are limited to a Cell because Gitaly is confined to a Cell.

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons

- We will break [snippet discovery](/ee/user/snippets.md#discover-snippets).
- Snippet access may become subordinate to the visibility of the Organization.
