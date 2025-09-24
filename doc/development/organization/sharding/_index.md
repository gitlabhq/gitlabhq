---
stage: Tenant Scale
group: Organizations
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
description: Guidance and principles for sharding database tables to support organization isolation
title: Sharding guidelines
---

The sharding initiative is a long-running project to ensure that most GitLab database tables can be related to an `Organization`, either directly or indirectly. This involves adding an `organization_id`, `namespace_id` or `project_id` column to tables, and backfilling their `NOT NULL` fallback data. This work is important for the delivery of Cells and Organizations. For more information, see the [design goals of Organizations](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/organization/#organization-sharding).

## Sharding principles

Follow this guidance to complete the remaining sharding key work and resolve outstanding issues.

## Use unique issues for each table

We have a number of tables which share an issue. For example, [eight tables point to the same issue here](https://gitlab.com/search?search=sharding_key_issue_url%3A%20https%3A%2F%2Fgitlab.com%2Fgitlab-org%2Fgitlab%2F-%2Fissues%2F493768&nav_source=navbar&project_id=278964&group_id=9970&search_code=true&repository_ref=master). This makes tracking progress and resolving blockers difficult.
You should break out these shared issues into a single one per table, and update the YAML files to match.

## Update unresolved, closed issues

Some of the issues linked in the database YAML docs have been closed, sometimes in favor of new issues, but the YAML files still point to the original URL.
You should update these to point to the correct items to ensure we're accurately measuring progress.

## Add more information to sharding issues

Every sharding issue should have an assignee, an associated milestone, and should link to blockers, if applicable.
This helps us plan the work and estimate completion dates. It also ensures each issue names someone to contact in the case of problems or concerns. It also helps us to visualize the project work by highlighting blocker issues so we can help resolve them.

Note that a blocker can be a dependency. For example, the `notes` table needs to be fully migrated before other tables can proceed. Any downstream issues should mark the related item as a blocker to help us understand these relationships.
