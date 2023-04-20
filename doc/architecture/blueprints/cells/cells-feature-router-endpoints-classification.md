---
stage: enablement
group: Tenant Scale
description: 'Cells: Router Endpoints Classification'
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

# Cells: Router Endpoints Classification

Classification of all endpoints is essential to properly route request
hitting load balancer of a GitLab installation to a Cell that can serve it.

Each Cell should be able to decode each request and classify for which Cell
it belongs to.

GitLab currently implements hundreds of endpoints. This document tries
to describe various techniques that can be implemented to allow the Rails
to provide this information efficiently.

## 1. Definition

## 2. Data flow

## 3. Proposal

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
