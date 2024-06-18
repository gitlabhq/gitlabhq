---
status: ongoing
creation-date: "2024-05-27"
authors: [ "@fabiopitino", "@mbobin" ]
coach: [ "@fabiopitino", "@grzesiek" ]
approvers: [ "@jreporter", "@cheryl.li" ]
owning-stage: "~devops::verify"
description: 'Reduce the growth rate of pipeline data'
---

<!-- vale gitlab.FutureTense = NO -->

# Reduce the growth rate of pipeline data

## Problem to solve

TODO 

## Strategies

### Delete pipeline processing data

Once a build gets archived, it is no longer possible to resume
pipeline processing in such pipeline. It means that all the metadata, we store
in PostgreSQL, that is needed to efficiently and reliably process builds can be
safely moved to a different data store.

Storing pipeline processing data is expensive as this kind of CI/CD
data represents a significant portion of data stored in CI/CD tables. Once we
restrict access to processing archived pipelines, we can move this metadata to
a different place - preferably object storage - and make it accessible on
demand, when it is really needed again (for example for compliance or auditing purposes).

We need to evaluate whether moving data is the most optimal solution. We might
be able to use de-duplication of metadata entries and other normalization
strategies to consume less storage while retaining ability to query this
dataset. Technical evaluation will be required to find the best solution here.

Epic: [Reduce the rate of builds metadata table growth](https://gitlab.com/groups/gitlab-org/-/epics/7434).
