---
stage: enablement
group: Tenant Scale
description: 'Cells: Contributions: Forks'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the Cells design.
Significant aspects are not documented, though we expect to add them in the future.
This is one possible architecture for Cells, and we intend to contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that we can document the reasons for not choosing this approach.

# Cells: Contributions: Forks

The [forking workflow](../../../../user/project/repository/forking_workflow.md) allows users to copy existing Project sources into their own namespace of choice (personal or Group).

## 1. Definition

The [forking workflow](../../../../user/project/repository/forking_workflow.md) is a common workflow with various usage patterns:

- It allows users to contribute back to an upstream Project.
- It persists repositories into their personal namespace.
- Users can copy a Project to make changes and release it as a modified Project.

Forks allow users not having write access to a parent Project to make changes.
The forking workflow is especially important for the open-source community to contribute back to public Projects.
However, it is equally important in some companies that prefer a strong split of responsibilities and tighter access control.
The access to a Project is restricted to a designated list of developers.

Forks enable:

- Tighter control of who can modify the upstream Project.
- Split of responsibilities: Parent Project might use CI configuration connecting to production systems.
- To run CI pipelines in the context of a fork in a much more restrictive environment.
- To consider all forks to be unvetted which reduces risks of leaking secrets, or any other information tied to the Project.

The forking model is problematic in a Cells architecture for the following reasons:

- Forks are clones of existing repositories. Forks could be created across different Organizations, Cells and Gitaly shards.
- Users can create merge requests and contribute back to an upstream Project. This upstream Project might be in a different Organization and Cell.
- The merge request CI pipeline is executed in the context of the source Project, but presented in the context of the target Project.

## 2. Data exploration

From a [data exploration](https://gitlab.com/gitlab-data/product-analytics/-/issues/1380), we retrieved the following information about existing forks:

- Roughly 1.8m forks exist on GitLab.com at the moment.
- The majority of forks are under a personal namespace (82%).
- We were expecting a minimal use of forks within the same top-level Group and/or organization. Forking is only necessary for users who don't have permissions to access a Project. Inside companies we wouldn't expect teams to use forking workflows much unless they for some reason have different permissions across different team members. The data showed that only 9% of fork relationships have matching ultimate parent namespace identifiers (top-level Groups and personal namespaces). The other 91% of fork relationships are forked across different top-level namespaces. When trying to match top-level Groups to an identifiable company, we saw that:
  - 3% of forked Projects are forked from an upstream Project in the same organization.
  - 83% of forked Projects do not have an identifiable organization related to either up or downstream Project.
  - The remaining 14% are forked from a source Project within a different company.
- 9% of top-level Groups (95k) with activity in the last 12 months have a project with a fork relationship, compared to 5% of top-level Groups (91k) with no activity in the last 12 months. We expect these top-level Groups to be impacted by Cells.

## 3. Proposals

### 3.1. Forks are created in a dedicated contribution space of the current Organization

Instead of creating Projects across Organizations, forks are created in a contribution space tied to the Organization.
A contribution space is similar to a personal namespace but rather than existing in the default Organization, it exists within the Organization someone is trying to contribute to.
Example:

- Any User that can view an Organization (all Users for public Organizations) can create a contribution space in the Organization. This is a dedicated namespace where they can create forks of Projects in that Organization. For example for `Produce Inc.` it could be `gitlab.com/organization/produce-inc/@ayufan`.
- To create a contribution space we do not require membership of an Organization as this would prevent open source workflows where contributors are able to fork and create a merge request without ever being invited to a Group or Project. We strictly respect visibility, so Users would not be able to create a fork in a private Organization without first being invited.
- When creating a fork for a Project Users will only be presented with the option to create forks in Groups that are part of the Organization. We will also give Users the option to create a contribution space and put the fork there. Today there is also a "Create a group" option when creating a fork. This functionality would also be limited to creating a new group in the organization to store the new fork.
- In order to support Users that want to fork without contributing back we might consider an option to create [an unlinked fork](../../../../user/project/repository/forking_workflow.md#unlink-a-fork) in any namespace they have permission to write to.
- The User has as many contribution spaces as Organizations they contribute to.
- The User cannot create additional personal Projects within contribution spaces. Personal Projects can continue to be created in their personal namespace.
- The Organization can prevent or disable usage of contribution spaces. This would disable forking by anyone that does not belong to a Group within the Organization.
- All current forks are migrated into the contribution space of the User in an Organization. Because this may result in data loss when the fork also has links to data outside of the upstream Project we will also keep the personal Project around as archived and remove the fork relationship.
- All forks are part of the Organization.
- Forks are not federated features.
- The contribution space and forked Project do not share configuration with the parent Project.
- If the Organization is deleted, the Projects containing forks will be moved either to the default Organization or we'll create a new Organization to house them, which is essentially a ghost Organization of the former Organization.
- Data in contribution spaces do not contribute to customer usage from a billing perspective.
- Today we do not have organization-scoped runners but if we do implement that they will likely need special settings for how or if they can be used by contribution space projects.

### 3.2. Intra-cluster forks

This proposal implements forks as intra-cluster forks where communication is done via API between all trusted Cells of a cluster:

- Forks are created always in the context of a user's choice of Group.
- Forks are isolated from the Organization.
- Organization or Group owner could disable forking across Organizations, or forking in general.
- A merge request is created in the context of the target Project, referencing the external Project on another Cell.
- To target Project the merge reference is transferred that is used for presenting information in context of the target Project.
- CI pipeline is fetched in the context of the source Project as it is today, the result is fetched into the merge request of the target Project.
- The Cell holding the target Project internally uses GraphQL to fetch the status of the source Project and includes in context of the information for merge request.

Pros:

- All existing forks continue to work as they are, as they are treated as intra-Cluster forks.

Cons:

- The purpose of Organizations is to provide strong isolation between Organizations. Allowing to fork across does break security boundaries.
- However, this is no different to the ability of users today to clone a repository to a local computer and push it to any repository of choice.
- Access control of the source Project can be lower than that of the target Project. Today, the system requires that in order to contribute back, the access level needs to be the same for fork and upstream Project.

### 3.3. Forks are created as internal Projects under current Projects

Instead of creating Projects across Organizations, forks are attachments to existing Projects.
Each user forking a Project receives their unique Project.
Example:

- For Project: `gitlab.com/gitlab-org/gitlab`, forks would be created in `gitlab.com/gitlab-org/gitlab/@kamil-gitlab`.
- Forks are created in the context of the current Organization, they do not cross Organization boundaries and are managed by the Organization.
- Tied to the user (or any other user-provided name of the fork).
- Forks are not federated features.

Cons:

- Does not answer how to handle and migrate all existing forks.
- Might share current Group/Project settings, which could be breaking some security boundaries.

### 3.4. Forks are created in personal namespaces of the current Organization

Every User can potentially have a personal namespace in each public Organization.
On the first visit to an Organization the User will receive a personal namespace scoped to that Organization.
A User can fork into a personal namespace provided the upstream repository is in the same Organization as the personal namespace.
Removal of an Organization will remove any personal namespaces in the Organization.

Pros:

- We re-use most existing code paths.
- We re-use most existing product design rules.
- Organization boundaries are naturally isolated.
- Multiple personal namespaces will mean Users can divide personal Projects across Organizations instead of having them mixed together.
- We expect most Users to work in one Organization, which means that the majority of them would not need to remember in which Organization they stored each of their personal Projects.

Cons:

- Redundant personal namespaces will be created. We expect to improve this in future iterations.
- Multiple personal namespaces could be difficult to navigate, especially when working across a large number of Organizations. We expect this to be an edge case.
- The life cycle of personal namespaces will be dependent on the Organization as is already the case for user accounts privately owned (such as Enterprise Users), and self-managed installations that are not public.
- Organization personal namespaces will need new URL paths.
- The legacy personal namespace path will need to be adapted.

URL path changes are under [discussion](https://gitlab.com/gitlab-org/gitlab/-/issues/427367).

## 4. Evaluation

We will follow [3.4. Forks are created in personal namespaces of the current Organization](#34-forks-are-created-in-personal-namespaces-of-the-current-organization) because it has already solved a lot of the hard problems.
The short falls of this solution like reworking URL paths or handling multiple personal namespaces are manageable and less critical than problems created through other alternative proposals.

## 5. Example

As an example, we will demonstrate the impact of this proposal for the case that we move `gitlab-org/gitlab` to a different Organization.
`gitlab-org/gitlab` has [over 8K forks](https://gitlab.com/gitlab-org/gitlab/-/forks).

### Does this direction impact the canonical URLs of those forks?

Yes canonical URLs will change for forks.
Specific path changes are under [discussion](https://gitlab.com/gitlab-org/gitlab/-/issues/427367).
Existing Users that have forks in legacy personal namespaces and want to continue contributing merge requests, will be required to migrate their fork to their personal namespace in the source project Organization.
For example, a personal namespace fork at `https://gitlab.com/DylanGriffith/gitlab` will need to be migrated to `https://gitlab.com/-/organizations/gitlab-inc/@DylanGriffith/gitlab`.
We may offer automated ways to move this, but manually the process would involve:

1. Create the contribution space fork
1. Push your local branch from your original fork to the new fork
1. Recreate any merge request that was still open and you wanted to merge

### Does it impact the Git URL of the repositories themselves?

Yes.
Specific path changes are under [discussion](https://gitlab.com/gitlab-org/gitlab/-/issues/427367).

### Would there be any user action required to accept their fork being moved within an Organization or towards a contribution space?

No. If the Organization is public, then a user will have a personal namespace.

### Can we make promises that we will not break the existing forks of public Projects hosted on GitLab.com?

Existing fork projects will not be deleted but their fork relationship will be
removed when the source project is moved to another Organization.
The owner of the open source project will be made aware that they will disconnect their
forks when they move the project which will require them to close all existing
merge requests from those forks.
There will need to be some process for keeping the history from these merge requests while effectively losing the ability to
collaborate on them or merge them.

In the case of `gitlab-org/gitlab` we will attempt to give as much notice of this process and make this process as transparent as possible.
When we make the decision to move this project to an Organization we will seek additional
feedback about what would be the minimum amount of automated migrations necessary to be acceptable here.
But the workflow for contributors will change after the move so this will be a punctuated event regardless.
