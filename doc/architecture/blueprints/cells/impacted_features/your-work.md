---
stage: enablement
group: Tenant Scale
description: 'Cells: Your Work'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: Your Work

Your Work will be scoped to an Organization.
Counts presented in the individual dashboards will relate to the selected Organization.

## 1. Definition

When accessing `gitlab.com/dashboard/`, users can find a [focused view of items that they have access to](../../../../tutorials/left_sidebar/index.md#use-a-more-focused-view).
This overview contains dashboards relating to:

- Projects
- Groups
- Issues
- Merge requests
- To-Do list
- Milestones
- Snippets
- Activity
- Workspaces
- Environments
- Operations
- Security

## 2. Data flow

## 3. Proposal

Your Work will be scoped to an Organization, giving the user an overview of all the items they can access in the Organization they are currently viewing.

- Issue, Merge request and To-Do list counts will refer to the selected Organization.
- The URL will reference the Organization with the following URL structure `/-/organizations/<organization>/dashboard`.
- The default URL `/dashboard` will refer to the [Home Organization](../impacted_features/user-profile.md#3-proposal).

## 4. Evaluation

Scoping Your Work to an Organization makes sense in the context of the [proposed Organization navigation](https://gitlab.com/gitlab-org/gitlab/-/issues/417778).
Considering that [we expect most users to work in a single Organization](../../organization/index.md#data-exploration), we deem this impact acceptable.

## 4.1. Pros

- Viewing Your Work scoped to an Organization allows Users to focus on content that is most relevant to their currently selected Organization.

## 4.2. Cons

- Users working across multiple Organizations will have to go to each Organization to access all of their work items.
