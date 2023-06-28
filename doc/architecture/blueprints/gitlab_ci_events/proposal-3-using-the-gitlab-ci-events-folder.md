---
owning-stage: "~devops::verify"
description: 'GitLab CI Events Proposal 3: Using the .gitlab/ci/events folder'
---

# GitLab CI Events Proposal 3: Using the `.gitlab/ci/events` folder

In this proposal we want to create separate files for each group of events. We
can define events in the following format:

```yaml
# .gitlab/ci/events/package-published.yml

spec:
  events:
    - name: package/published
---
include:
  - local: .gitlab-ci.yml
    with:
      event: $[[ gitlab.event.name ]]
```

And in the `.gitlab-ci.yml` file, we can use the input;

```yaml
# .gitlab-ci.yml

spec:
  inputs:
    event:
      default: push
---
job1:
  script: echo "Hello World"

job2:
  script: echo "Hello World"

job-for-package-published:
  script: echo "Hello World"
  rules:
    - if: $[[ inputs.event ]] == "package/published"
```

When an event happens;

1. We'll enqueue a new job for the event.
1. The job will search for the event file in the `.gitlab/ci/events` folder.
1. The job will run `Ci::CreatePipelineService` for the event file.

## Problems & Questions

1. For every defined event run, we need to enqueue a new job.
1. Every event-job will need to search for files.
1. This would be only for the project-scope events.
1. This will not work for GitLab.com scale.
