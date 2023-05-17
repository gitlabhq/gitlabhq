---
owning-stage: "~devops::verify"
description: 'GitLab CI Events Proposal 2: Using the rules keyword'
---

# GitLab CI Events Proposal 2: Using the `rules` keyword

Can we do it with our current [`rules`](../../../ci/yaml/index.md#rules) system?

```yaml
workflow:
  rules:
    - events: ["package/*"]

test_package_published:
  script: echo testing published package
  rules:
    - events: ["package/published"]

test_package_removed:
  script: echo testing removed package
  rules:
    - events: ["package/removed"]
```

1. We don't upsert anything to the database.
1. We'll have a single worker which subcribes to events
like `store.subscribe ::Ci::CreatePipelineFromEventWorker, to: ::Issues::CreatedEvent`.
1. The worker just runs `Ci::CreatePipelineService` with the correct parameters, the rest
will be handled by the `rules` system. Of course, we'll need modifications to the `rules` system to support `events`.

## Problems & Questions

1. For every defined event run, we need to enqueue a new `Ci::CreatePipelineFromEventWorker` job.
1. The worker will need to run `Ci::CreatePipelineService` for every event run.
This may be costly because we go through every cycle of `Ci::CreatePipelineService`.
1. This would be highly inefficient.
1. Can we move the existing workflows into the new CI events, for example, `merge_request_event`?
