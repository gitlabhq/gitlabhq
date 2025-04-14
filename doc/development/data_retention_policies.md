---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Data Retention Guidelines for Feature Development
---

## Overview

Data retention is a critical aspect of feature development at GitLab. As we build and maintain features, we must consider the lifecycle of the data we collect and store. This document outlines the guidelines for incorporating data retention considerations into feature development from the outset.

## Why data retention matters

- **System performance**: Time-based data organization enables better query optimization and efficient data access patterns, leading to faster response times and improved system scalability.
- **Infrastructure cost**: Strategic storage management through data lifecycle policies reduces infrastructure costs for primary storage, backups, and disaster recovery systems.
- **Engineering efficiency**: Designing features with data retention in mind from the start makes development faster and more reliable by establishing clear data lifecycles, reducing technical debt and faster data migrations.

## Guidelines for feature development

### 1. Early planning

When designing new features, consider data retention requirements during the initial planning phase:

- Document the types of data being persisted. Is this user-facing data?
  Is it generated internally to make processing more efficient?
  Is it derived/cache data?
- Identify the business purpose and required retention period for each data type.
- Define the product justification and customer usage pattern of older data.
  How do people interact with older data as opposed to newer data?
  How does the value change over time?
- Consider regulatory requirements that might affect data retention (such as Personally Identifiable Information).
- Plan for data removal or archival mechanisms.

### 2. Design for data lifecycle

Features should be designed with the understanding that data is not permanent:

- Avoid assumptions about infinite data availability.
- Implement graceful handling of missing or archived data.
- Design user interfaces to clearly communicate data availability periods.
- Design data structures for longer-term storage that is optimized to be viewed in a longer-term context.
- Consider implementing "time to live" (TTL) mechanisms where appropriate, especially for derived/cache data
  that can be gracefully reproduced on-demand.

### 3. Documentation recommendations

Each feature implementation must include:

- Clear documentation of data retention periods (on GitLab.com and default values, if any)
  and business reasoning/justification
- Description of data removal/archival mechanisms.
- Impact analysis of data removal on dependent features.

## Implementation checklist

Before submitting a merge request for a new feature:

- [ ] Document data retention requirements.
- [ ] Design data models with data removal in mind.
- [ ] Implement data removal/archival mechanisms.
- [ ] Test feature behavior with missing/archived data.
- [ ] Include retention periods in user documentation.
- [ ] Consider impact on dependent features.
- [ ] Consider impact on backups/restores and export/import.
- [ ] Consider impact on replication (eg Geo).

## Related links

- [Large tables limitations](database/large_tables_limitations.md)
