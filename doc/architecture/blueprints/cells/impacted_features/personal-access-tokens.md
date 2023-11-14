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

### 3.1. Organization-scoped PATs

Pros:

- Can be managed entirely from Rails application.
- Increased security. PAT is limited only to Organization.

Cons:

- Different PAT needed for different Organizations.
- Cannot tell at a glance if PAT will apply to a certain Project/Namespace.

### 3.2. Cluster-wide PATs

Pros:

- User does not have to worry about which scope the PAT applies to.

Cons:

- User has to worry about wide-ranging scope of PAT (e.g. separation of personal items versus work items).
- Organization cannot limit scope of PAT to only their Organization.
- Increases complexity. All cluster-wide data likely will be moved to a separate [data access layer](../../cells/index.md#1-data-access-layer).

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
