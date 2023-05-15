---
owning-stage: "~devops::verify"
description: 'GitLab CI Events Proposal 1: Using the .gitlab-ci.yml file'
---

# GitLab CI Events Proposal 1: Using the `.gitlab-ci.yml` file

Currently, we have two proof-of-concept (POC) implementations:

- [GitLab CI Workflows PoC](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91244)
- [PoC NPM CI events](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111693)

They both have similar ideas;

1. Find a new CI Config syntax to define the pipeline events.

    Example 1:

    ```yaml
    workflow:
      events:
        - events/package/published

    # or

    workflow:
      on:
        - events/package/published
    ```

    Example 2:

    ```yaml
    spec:
      on:
        - events/package/published
        - events/package/removed
      # on:
      #   package: [published, removed]
    ---
    do_something:
      script: echo "Hello World"
    ```

1. Upsert an event to the database when creating a pipeline.
1. Create [EventStore subscriptions](../../../development/event_store.md) to handle the events.

## Problems & Questions

1. The CI config of a project can be anything;
    - `.gitlab-ci.yml` by default
    - another file in the project
    - another file in another project
    - completely a remote/external file

    How do we handle these cases?
1. Since we have these problems above, should we keep the events in its own file? (`.gitlab-ci-events.yml`)
1. Do we only accept the changes in the main branch?
1. We try to create event subscriptions every time a pipeline is created.
1. Can we move the existing workflows into the new CI events, for example, `merge_request_event`?
