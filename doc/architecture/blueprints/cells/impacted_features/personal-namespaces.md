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

Personal Namespaces do not easily fit with our overall architecture in Cells, because the Cells architecture depends on all data belonging to a single Organization.
When Users are allowed to work across multiple Organizations there is no natural fit for picking a single Organization to store personal Namespaces and their Projects.

One important engineering constraint in Cells will be that data belonging to one Organization should not be linked to data belonging to another Organization.
Specifically, functionality in GitLab should be scoped to a single Organization at a time.
This presents a challenge for personal Namespaces as forking is one of the important workloads for personal Namespaces.
Functionality related to forking and the UI that presents forked MRs to users will often require data from both the downstream and upstream Projects at the same time.
Implementing such functionality would be very difficult if that data belonged to different Organizations stored on different
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

### 3.1. One personal Namespace that can move between Organizations

For existing Users personal Namespaces will exist within the default Organization in the short term.
This implies that all Users will, at first, have an association to the default Organization via their personal Namespace.
When a new Organization is created, new Users can be created in that Organization as well.
A new User's personal Namespace will be associated with that new Organization, rather than the default.
Also, Users can become members of Organizations other than the default Organization.
In this case, they will have to switch to the default Organization to access their personal Namespace until we have defined a way for them to move their personal Namespace into a different Home Organization.
Doing so may necessitate that personal Namespaces are converted to Groups before being moved.
When an Organization is deleted, we will need to decide what should happen with the personal Namespaces associated with it.
If we go this route, there may be breakage similar to what will happen to when we move Groups or Projects into their own Organization, though the full impact may need further investigation.

This decision, however, means that existing personal Namespaces that were used as forks to contribute to some upstream Project will become disconnected from the upstream as soon as the upstream moves into an Organization.
On GitLab.com 10% of all projects in personal Namespaces are forks.
This may be a slightly disruptive workflow but as long as the forks are mainly just storing branches used in merge requests then it may be reasonable to ask the affected users to recreate the fork in the context of the Organization.

We will further explore the idea of a `contribution space` to give Users a place to store forks when they want to contribute to a Project where they don't have permission to push a branch.
That discussion will be handled as part of the larger discussion of the [Cells impact on forks](../impacted_features/contributions-forks.md).

Pros:

- Easy access to personal Namespace via a User's Home Organization. We expect most Users to work in only a single Organization.
- Contribution graph would remain intact for Users that only work in one Organization, because their personal and organizational activity would be aggregated as part of the same Organization.

Cons:

- A transfer mechanism to move personal Namespaces between Organizations would need to be built, which is extremely complex. This would be in violation of the current Cells architecture, because Organizations can be located on different Cells. To make this possible, we would need to break Organization isolation.
- High risk that transfer between Organizations would lead to breaking connections and data loss.
- [Converting personal Namespaces to Groups](../../../../tutorials/convert_personal_namespace_to_group/index.md) before transfer is not a straightforward process.

### 3.2. One personal Namespace that remains in the default Organization

For existing Users personal Namespaces will exist within the default Organization in the short term.
This implies that all Users will, at first, have an association to the default Organization via their personal Namespace.
New Users joining GitLab as part of an Organization other than the default Organization would also receive a personal Namespace in the default Organization.
Organization other than the default Organization would not contain personal Namespaces.

Pros:

- No transfer mechanism necessary.

Cons:

- Users that are part of multiple Organizations need to remember that their personal content is stored in the default Organization. To access it, they would have to switch back to the default Organization.
- New Users might not understand why they are part of the default Organization.
- Some impact on the User Profile page. No personal Projects would be shown in Organizations other than the default Organization. This would result in a lot of whitespace on the page. The `Personal projects` list would need to be reworked as well.

### 3.3. One personal Namespace in each Organization

For existing Users personal Namespaces will exist within the default Organization in the short term.
As new Organizations are created, Users receive additional personal Namespaces for each Organization they interact with.
For instance, when a User views a Group or Project in an Organization, a personal Namespace is created.
This is necessary to ensure that community contributors will be able to continue contributing to Organizations without becoming a member.

Pros:

- Content of personal Projects is owned by the Organization. Low risk for enterprises to leak content outside of their organizational boundaries.
- No transfer mechanism necessary.
- No changes to the User Profile page are necessary.
- Users can keep personal Projects in each Organization they work in.
- No contribution space for [forking](../impacted_features/contributions-forks.md) necessary.
- No need to make the default Organization function differently than other Organizations.

Cons:

- Users have to remember which personal content they store in each Organization.
- Personal content would be owned by the Organization. However, this would be similar to how self-managed operates today and might be desired by enterprises.

### 3.4. Discontinue personal Namespaces

All existing personal Namespaces are converted into Groups.
The Group path is identical to the current username.
Upon Organization release, these Groups would be part of the default Organization.
We disconnect Users from the requirement of having personal Namespaces, making the User a truly global entity.

Pros:

- Users would receive the ability to organize personal Projects into Groups, which is a highly requested feature.
- No need to create personal Namespaces upon User creation.
- No path changes necessary for existing personal Projects.

Cons:

- A concept of personal Groups would need to be established.
- It is unclear how @-mentions would work. Currently it is possible to tag individual Users and Groups. Following the existing logic all group members belonging to a personal Group would be tagged.
- Significant impact on the User Profile page. Personal Projects would be disconnected from the User Profile page and possibly replaced by new functionality to highlight specific Projects selected by the User (via starring or pinning).
- It is unclear whether Groups could be migrated between Organizations using the same mechanism as needed to migrate top-level Groups. We expect this functionality to be highly limited at least in the mid-term. Similar transfer limitations as described in [section 3.1.](#31-one-personal-namespace-that-can-move-between-organizations) are expected.

## 4. Evaluation

We will begin by [making the personal namespace optional for Organizations](https://gitlab.com/groups/gitlab-org/-/epics/12179). The goal of this iteration is to disable personal namespaces for any Organization other than the default Organization, so that customers who do not want to use personal namespaces can already move to Organizations. The first phase will only change the Ruby on Rails model relationships in preparation for further changes at the user-facing level.

We need to [split the concept of a User Profile and a personal namespace](https://gitlab.com/gitlab-org/gitlab/-/issues/432654) now that a User is cluster-wide and a User's personal namespace must be Cell-local. It is likely we will [discontinue personal namespaces](#34-discontinue-personal-namespaces) in favor of Groups.
