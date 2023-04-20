---
stage: enablement
group: Tenant Scale
description: 'Cells: Global search'
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

# Cells: Global search

When we introduce multiple Cells we intend to isolate all services related to
those Cells. This will include Elasticsearch which means our current global
search functionality will not work. It may be possible to implement aggregated
search across all cells, but it is unlikely to be performant to do fan-out
searches across all cells especially once you start to do pagination which
requires setting the correct offset and page number for each search.

## 1. Definition

## 2. Data flow

## 3. Proposal

Likely first versions of Cells will simply not support global searches and then
we may later consider if building global searches to support popular use cases
is worthwhile.

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
