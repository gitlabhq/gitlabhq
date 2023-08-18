---
stage: enablement
group: Tenant Scale
description: 'Cells: Contributions: Forks'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: Contributions: Forks

The [Forking workflow](../../../../user/project/repository/forking_workflow.md) allows users to copy existing Project sources into their own namespace of choice (Personal or Group).

## 1. Definition

The [Forking workflow](../../../../user/project/repository/forking_workflow.md) is a common workflow with various usage patterns:

- It allows users to contribute back to upstream Project.
- It persists repositories into their Personal Namespace.
- Users can copy to make changes and release as modified Project.

Forks allow users not having write access to a parent Project to make changes.
The forking workflow is especially important for the open source community to contribute back to public Projects.
However, it is equally important in some companies that prefer a strong split of responsibilities and tighter access control.
The access to a Project is restricted to a designated list of developers.

Forks enable:

- Tighter control of who can modify the upstream Project.
- Split of responsibilities: Parent Project might use CI configuration connecting to production systems.
- To run CI pipelines in the context of a fork in a much more restrictive environment.
- To consider all forks to be unvetted which reduces risks of leaking secrets, or any other information tied to the Project.

The forking model is problematic in a Cells architecture for the following reasons:

- Forks are clones of existing repositories. Forks could be created across different Organizations, Cells and Gitaly shards.
- Users can create merge requests and contribute back to an upstream Project. This upstream Project might in a different Organization and Cell.
- The merge request CI pipeline is executed in the context of the source Project, but presented in the context of the target Project.

## 2. Data flow

## 3. Proposals

### 3.1. Intra-Cluster forks

This proposal implements forks as intra-Cluster forks where communication is done via API between all trusted Cells of a cluster:

- Forks are created always in the context of a user's choice of Group.
- Forks are isolated from the Organization.
- Organization or Group owner could disable forking across Organizations, or forking in general.
- A merge request is created in the context of the target Project, referencing the external Project on another Cell.
- To target Project the merge reference is transferred that is used for presenting information in context of the target Project.
- CI pipeline is fetched in the context of the source Project as it is today, the result is fetched into the merge request of the target Project.
- The Cell holding the target Project internally uses GraphQL to fetch the status of the source Project and includes in context of the information for merge request.

Upsides:

- All existing forks continue to work as they are, as they are treated as intra-Cluster forks.

Downsides:

- The purpose of Organizations is to provide strong isolation between Organizations. Allowing to fork across does break security boundaries.
- However, this is no different to the ability of users today to clone a repository to a local computer and push it to any repository of choice.
- Access control of source Project can be lower than those of target Project. Today, the system requires that in order to contribute back, the access level needs to be the same for fork and upstream.

### 3.2. Forks are created in a Personal Namespace of the current Organization

Instead of creating Projects across Organizations, forks are created in a user's Personal Namespace tied to the Organization. Example:

- Each user that is part of an Organization receives their Personal Namespace. For example for `GitLab Inc.` it could be `gitlab.com/organization/gitlab-inc/@ayufan`.
- The user has to fork into their own Personal Namespace of the Organization.
- The user has as many Personal Namespaces as Organizations they belongs to.
- The Personal Namespace behaves similar to the currently offered Personal Namespace.
- The user can manage and create Projects within a Personal Namespace.
- The Organization can prevent or disable usage of Personal Namespaces, disallowing forks.
- All current forks are migrated into the Personal Namespace of user in an Organization.
- All forks are part of the Organization.
- Forks are not federated features.
- The Personal Namespace and forked Project do not share configuration with the parent Project.

### 3.3. Forks are created as internal Projects under current Projects

Instead of creating Projects across Organizations, forks are attachments to existing Projects.
Each user forking a Project receives their unique Project. Example:

- For Project: `gitlab.com/gitlab-org/gitlab`, forks would be created in `gitlab.com/gitlab-org/gitlab/@kamil-gitlab`.
- Forks are created in the context of the current Organization, they do not cross Organization boundaries and are managed by the Organization.
- Tied to the user (or any other user-provided name of the fork).
- Forks are not federated features.

Downsides:

- Does not answer how to handle and migrate all existing forks.
- Might share current Group/Project settings, which could be breaking some security boundaries.

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
