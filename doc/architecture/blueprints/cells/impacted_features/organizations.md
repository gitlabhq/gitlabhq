---
stage: enablement
group: Tenant Scale
description: 'Cells: Organizations'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: Organizations

One of the major designs of a Cells architecture is strong isolation between Groups.
Organizations as described by the [Organization blueprint](../../organization/index.md) provides a way to have plausible UX for joining together many Groups that are isolated from the rest of the system.

## 1. Definition

Cells do require that all Groups and Projects of a single Organization can only be stored on a single Cell because a Cell can only access data that it holds locally and has very limited capabilities to read information from other Cells.

Cells with Organizations do require strong isolation between Organizations.

It will have significant implications on various user-facing features, like Todos, dropdowns allowing to select Projects, references to other issues or Projects, or any other social functions present at GitLab.
Today those functions were able to reference anything in the whole system.
With the introduction of Organizations this will be forbidden.

This problem definition aims to answer effort and implications required to add strong isolation between Organizations to the system, including features affected and their data processing flow.
The purpose is to ensure that our solution when implemented consistently avoids data leakage between Organizations residing on a single Cell.

## 2. Proposal

See the [Organization blueprint](../../organization/index.md).
