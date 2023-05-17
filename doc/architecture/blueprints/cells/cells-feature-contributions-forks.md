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

[Forking workflow](../../../user/project/repository/forking_workflow.md) allows users
to copy existing project sources into their own namespace of choice (personal or group).

## 1. Definition

[Forking workflow](../../../user/project/repository/forking_workflow.md) is common workflow
with various usage patterns:

- allows users to contribute back to upstream project
- persist repositories into their personal namespace
- copy to make changes and release as modified project

Forks allow users not having write access to parent project to make changes. The forking workflow
is especially important for the Open Source community which is able to contribute back
to public projects. However, it is equally important in some companies which prefer the strong split
of responsibilites and tighter access control. The access to project is restricted
to designated list of developers.

Forks enable:

- tigther control of who can modify the upstream project
- split of the responsibilites: parent project might use CI configuration connecting to production systems
- run CI pipelines in context of fork in much more restrictive environment
- consider all forks to be unveted which reduces risks of leaking secrets, or any other information
  tied with the project

The forking model is problematic in Cells architecture for following reasons:

- Forks are clones of existing repositories, forks could be created across different organizations, Cells and Gitaly shards.
- User can create merge request and contribute back to upstream project, this upstream project might in a different organization and Cell.
- The merge request CI pipeline is to executed in a context of source project, but presented in a context of target project.

## 2. Data flow

## 3. Proposals

### 3.1. Intra-Cluster forks

This proposal makes us to implement forks as a intra-ClusterCell forks where communication is done via API
between all trusted Cells of a cluster:

- Forks when created, they are created always in context of user choice of group.
- Forks are isolated from Organization.
- Organization or group owner could disable forking across organizations or forking in general.
- When a Merge Request is created it is created in context of target project, referencing
  external project on another Cell.
- To target project the merge reference is transfered that is used for presenting information
  in context of target project.
- CI pipeline is fetched in context of source project as it-is today, the result is fetched into
  Merge Request of target project.
- The Cell holding target project internally uses GraphQL to fetch status of source project
  and include in context of the information for merge request.

Upsides:

- All existing forks continue to work as-is, as they are treated as intra-Cluster forks.

Downsides:

- The purpose of Organizations is to provide strong isolation between organizations
  allowing to fork across does break security boundaries.
- However, this is no different to ability of users today to clone repository to local computer
  and push it to any repository of choice.
- Access control of source project can be lower than those of target project. System today
  requires that in order to contribute back the access level needs to be the same for fork and upstream.

### 3.2. Forks are created in a personal namespace of the current organization

Instead of creating projects across organizations, the forks are created in a user personal namespace
tied with the organization. Example:

- Each user that is part of organization receives their personal namespace. For example for `GitLab Inc.`
  it could be `gitlab.com/organization/gitlab-inc/@ayufan`.
- The user has to fork into it's own personal namespace of the organization.
- The user has that many personal namespaces as many organizations it belongs to.
- The personal namespace behaves similar to currently offered personal namespace.
- The user can manage and create projects within a personal namespace.
- The organization can prevent or disable usage of personal namespaces disallowing forks.
- All current forks are migrated into personal namespace of user in Organization.
- All forks are part of to the organization.
- The forks are not federated features.
- The personal namespace and forked project do not share configuration with parent project.

### 3.3. Forks are created as internal projects under current project

Instead of creating projects across organizations, the forks are attachments to existing projects.
Each user forking a project receives their unique project. Example:

- For project: `gitlab.com/gitlab-org/gitlab`, forks would be created in `gitlab.com/gitlab-org/gitlab/@kamil-gitlab`.
- Forks are created in a context of current organization, they do not cross organization boundaries
  and are managed by the organization.
- Tied to the user (or any other user-provided name of the fork).
- The forks are not federated features.

Downsides:

- Does not answer how to handle and migrate all exisiting forks.
- Might share current group / project settings - breaking some security boundaries.

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
