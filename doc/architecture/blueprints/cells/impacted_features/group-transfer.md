---
stage: enablement
group: Tenant Scale
description: 'Cells: Group Transfer'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the Cells design.
Significant aspects are not documented, though we expect to add them in the future.
This is one possible architecture for Cells, and we intend to contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that we can document the reasons for not choosing this approach.

# Cells: Group Transfer

TL;DR

## 1. Definition

## 2. Data flow

## 3. Proposal

There is an [investigation](https://gitlab.com/gitlab-org/gitlab/-/issues/458338) to solve this problem using [direct transfer](../../../../user/group/import/index.md).

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons

Direct transfer does not migrate users and users cannot exist on more than one Cell. This means in Cells 1.0, for migrations across Cells, any user contributions will be assigned to the user performing the import.
