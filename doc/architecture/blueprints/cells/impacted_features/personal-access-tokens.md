---
stage: enablement
group: Tenant Scale
description: 'Cells: Personal Access Tokens'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: Personal Access Tokens

## 1. Definition

Personal Access Tokens (PATs) associated with a User are a way for Users to interact with the API of GitLab to perform operations.
PATs today are scoped to the User, and can access all Groups that a User has access to.

## 2. Data flow

## 3. Proposal

Various approaches have been discussed in the following issues / merge requests:

- [#428717](https://gitlab.com/gitlab-org/gitlab/-/issues/428717)
- [#428542](https://gitlab.com/gitlab-org/gitlab/-/issues/428542)
- [!136939](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136939)

### 3.1. Organization-scoped PATs

Pros:

- Can be managed entirely from Rails application.
- Increased security. PAT is limited only to Organization.
- API requests for a particular Cell can be routed based on the PAT.

Cons:

- Different PAT needed for different Organizations.
- Automations involving multiple projects across different Organizations will
  require multiple PATs to work - one for each Organization.
- Cannot tell at a glance if PAT will apply to a certain Project/Namespace.

## 4. Alternative approaches considered

### 4.1. Cluster-wide PATs

Pros:

- User does not have to worry about which scope the PAT applies to.

Cons:

- User has to worry about wide-ranging scope of PAT (e.g. separation of personal items versus work items).
- Organization cannot limit scope of PAT to only their Organization.
- Increases complexity. All cluster-wide data likely will be moved to a separate [data access layer](../../cells/index.md#1-data-access-layer).

### 4.2. Cluster-wide PATs with optional Organization scoping

This is a combination of option 3.1 and 4.1 where the PATs are created
cluster-wide but can be optionally scoped to an Organization.
For initial development, the implication would be to support clusterwide PATs
(including addressing any scalability challenges) and eventually adding
organization as a token scope (similar to API or read/write scopes).

Pros:

- Flexible and secure giving users (or admins) control over the PAT scope

Cons:

- Risk around discovering scalability [challenges](../index.md#1-data-access-layer)
  when accessing, sharing or updating clusterwide data.

## 5. Evaluation

## 5.1. Pros

## 5.2. Cons
