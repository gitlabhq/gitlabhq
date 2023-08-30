---
stage: enablement
group: Tenant Scale
description: 'Cells: Personal Namespaces'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the Cells design.
Significant aspects are not documented, though we expect to add them in the future.
This is one possible architecture for Cells, and we intend to contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that we can document the reasons for not choosing this approach.

# Cells: Personal Namespaces

Personal Namespaces do not easily fit with our overall architecture in Cells because the Cells architecture depends on all data belonging to a single Organization.
When Users are allowed to work across multiple Organizations there is no natural fit for picking a single Organization to store personal Namespaces and their Projects.

One important engineering constraint in Cells will be that data belonging to some Organization should not be linked to data belonging to another Organization.
And specifically that functionality in GitLab can be scoped to a single Organization at a time.
This presents a challenge for personal Namespaces as forking is one of the important workloads for personal Namespaces.
Functionality related to forking and the UI that presents forked MRs to users will often require data from both the downstream and upstream Projects at the same time.
Implementing such functionality would be very difficult if that data belonged in different Organizations stored on different
Cells.
This is especially the case with the merge request, as it is one of the most complicated and performance critical features in GitLab.

Today personal Namespaces serve two purposes that are mostly non-overlapping:

1. They provide a place for users to create personal Projects 
   that aren't expected to receive contributions from other people. This use case saves them from having to create a Group just for themselves.
1. They provide a default place for a user to put any forks they
   create when contributing to Projects where they don't have permission to push a branch. This again saves them from needing to create a Group just to store these forks. But the primary user need here is because they can't push branches to the upstream Project so they create a fork and contribute merge requests from the fork.

## 1. Definition

A [personal Namespace](../../../../user/namespace/index.md#types-of-namespaces) is based on a username and provided when a user creates an account.
Users can create [personal Projects](../../../../user/project/working_with_projects.md#view-personal-projects) under their personal Namespace.

## 2. Data flow

## 3. Proposal

As described above, personal Namespaces serve two purposes today:

1. A place for users to store their Projects to save them from creating a Group.
1. A place for users to store forks when they want to contribute to a Project where they don't have permission to push a branch.

In this proposal we will only focus on (1) and assume that (2) will be replaced by suitable workflows described in [Cells: Contributions: Forks](../impacted_features/contributions-forks.md).

Since we plan to move away from using personal Namespaces as a home for storing forks, we can assume that the main remaining use case does not need to support cross-Organization linking.
In this case the easiest thing to do is to keep all personal Namespaces in the default Organization.
Depending on the amount of workloads happening in personal Namespaces we may be required in the future to migrate them to different Cells.
This may necessitate that they all get moved to some Organization created just for the user.
If we go this route, there may be breakage similar to what will happen to when we move Groups or Projects into their own Organization, though the full impact may need further investigation.

This decision, however, means that existing personal Namespaces that were used as forks to contribute to some upstream Project will become disconnected from the upstream as soon as the upstream moves into an Organization.
On GitLab.com 10% of all projects in personal Namespaces are forks.
This may be a slightly disruptive workflow but as long as the forks are mainly just storing branches used in merge requests then it may be reasonable to ask the affected users to recreate the fork in the context of the Organization.

For existing Users, we suggest to keep their existing personal Namespaces in the default Organization.
New Users joining an Organization other than the default Organization will also have their personal Namespace hosted on the default Organization. Having all personal Namespaces in the default Organization means we don't need to worry about deletion of the parent organization and the impact of that on personal Namespaces, which would be the case if they existed in other organizations.
This implies that all Users will have an association to the default Organization via their personal Namespace, requiring them to switch to the default Organization to access their personal Namespace.

We will further explore the idea of a `contribution space` to give Users a place to store forks when they want to contribute to a Project where they don't have permission to push a branch.
That discussion will be handled as part of the larger discussion of the [Cells impact on forks](../impacted_features/contributions-forks.md).

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
