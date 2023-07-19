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

1. We don't upsert subscriptions to the database.
1. We'll have a single worker which runs when something happens in GitLab.
1. The worker just tries to create a pipeline with the correct parameters.
1. Pipeline runs when `rules` subsystem finds a job to run.

## Challenges

1. For every defined event run, we need to enqueue a new pipeline creation worker.
1. Creating pipelines and selecting builds to run is a relatively expensive operation
1. This will not work on GitLab.com scale.
