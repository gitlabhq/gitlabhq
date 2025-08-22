---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Development Considerations and Caveats
---

This guide helps contributors navigate common development challenges and avoid potential
pitfalls when working on GitLab CE and EE.

## Consider database and token formatting changes

All deployed code should be designed to support rollbacks, as they are often the fastest way to 
mitigate incidents. Engineer On Call (EOC) or Incident Manager On Call 
(IMOC) teams likely do not have full visibility into rollback impacts, so assume any deployment 
could be reversed.

In addition to following the [database migration guide](database/_index.md) for reversibility, 
pay special attention to data format changes that affect user-stored data.

When modifying formats for user-stored data (such as authentication tokens, configuration 
files, or cached values), consider using a phased deployment approach:

1. Phase 1: Deploy validation logic that accepts both old and new formats
1. Phase 2: Deploy issuance logic that creates data in the new format

This approach ensures:

- Older self-managed instances have backward compatibility support
- New format data is only created after validation logic is deployed
- Rollbacks won't create validation failures for newly-issued data
- Users experience no disruption during format transitions
