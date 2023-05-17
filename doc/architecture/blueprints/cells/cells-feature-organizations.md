---
stage: enablement
group: Tenant Scale
description: 'Cells: Organizations'
---

<!-- vale gitlab.FutureTense = NO -->

DISCLAIMER:
This page may contain information related to upcoming products, features and
functionality. It is important to note that the information presented is for
informational purposes only, so please do not rely on the information for
purchasing or planning purposes. Just like with all projects, the items
mentioned on the page are subject to change or delay, and the development,
release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: Organizations

One of the major designs of Cells architecture is strong isolation between Groups.
Organizations as described by this blueprint provides a way to have plausible UX
for joining together many Groups that are isolated from the rest of systems.

## 1. Definition

Cells do require that all groups and projects of a single organization can
only be stored on a single Cell since a Cell can only access data that it holds locally
and has very limited capabilities to read information from other Cells.

Cells with Organizations do require strong isolation between organizations.

It will have significant implications on various user-facing features,
like Todos, dropdowns allowing to select projects, references to other issues
or projects, or any other social functions present at GitLab. Today those functions
were able to reference anything in the whole system. With the introduction of
organizations such will be forbidden.

This problem definition aims to answer effort and implications required to add
strong isolation between organizations to the system. Including features affected
and their data processing flow. The purpose is to ensure that our solution when
implemented consistently avoids data leakage between organizations residing on
a single Cell.

## 2. Data flow

## 3. Proposal

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
