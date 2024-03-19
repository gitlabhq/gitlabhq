---
status: proposed
creation-date: "2023-03-15"
authors: [ "@furkanayhan" ]
owners: [ "@fabiopitino" ]
coach: "@grzesiek"
approvers: [ "@fabiopitino", "@jreporter", "@cheryl.li" ]
owning-stage: "~devops::verify"
participating-stages: [ "~devops::package", "~devops::deploy" ]
---

# GitLab CI Events

## Summary

In order to unlock innovation and build more value, GitLab is expected to be
the center of automation related to DevSecOps processes. We want to transform
GitLab into a programming environment, that will make it possible for engineers
to model various workflows on top of CI/CD pipelines. Today, users must create
custom automation around webhooks or scheduled pipelines to build required
workflows.

In order to make this automation easier for our users, we want to build a
powerful CI/CD eventing system, that will make it possible to run pipelines
whenever something happens inside or outside of GitLab.

A typical use-case is to run a CI/CD job whenever someone creates an issue,
posts a comment, changes a merge request status from "draft" to "ready for
review" or adds a new member to a group.

To build that new technology, we should:

1. Emit many hierarchical events from within GitLab in a more advanced way than we do it today.
1. Make it affordable to run this automation, that will react to GitLab events, at scale.
1. Provide a set of conventions and libraries to make writing the automation easier.

## Goals

While ["GitLab Events Platform"](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113700)
aims to build new abstractions around emitting events in GitLab, "GitLab CI
Events" blueprint is about making it possible to:

1. Define a way in which users will configure when an event emitted will result in a CI pipeline being run.
1. Describe technology required to match subscriptions with events at GitLab.com scale and beyond.
1. Describe technology we could use to reduce the cost of running automation jobs significantly.

## Proposal

### Decisions

- [001: Use hierarchical events](decisions/001_hierarchical_events.md)

### Requirements

Any accepted proposal should take in consideration the following requirements and characteristics:

1. Defining events should be done in separate files.
    - If we define all events in a single file, then the single file gets too complicated and hard to
      maintain for users. Then, users need to separate their configs with the `include` keyword again and we end up
      with the same solution.
    - The structure of the pipelines, the personas and the jobs will be different depending on the events being
      subscribed to and the goals of the subscription.
1. A single subscription configuration file should define a single pipeline that is created when an event is triggered.
    - The pipeline config can include other files with the `include` keyword.
    - The pipeline can have many jobs and trigger child pipelines or multi-project pipelines.
1. The events and handling syntax should use the existing CI config syntax where it is pragmatic to do so.
    - It'll be easier for users to adapt. It'll require less work to implement.
1. The event subscription and emiting events should be performant, scalable, and non blocking.
    - Reading from the database is usually faster than reading from files.
    - A CI event can potentially have many subscriptions.
      This also includes evaluating the right YAML files to create pipelines.
    - The main business logic (e.g. creating an issue) should not be affected
      by any subscriptions to the given CI event (e.g. issue created).
1. The CI events design should be implemented in a maintainable and extensible way.
    - If there is a `issues/create` event, then any new event (`merge_request/created`) can be added without
      much effort.
    - We expect that many events will be added. It should be trivial for developers to
      register domain events (e.g. 'issue closed') as GitLab-defined CI events.
    - Also, we should consider the opportunity of supporting user-defined CI events long term (e.g. 'order shipped').

### Options

For now, we have technical 5 proposals;

1. [Proposal 1: Using the `.gitlab-ci.yml` file](proposal-1-using-the-gitlab-ci-file.md)
    Based on;
    - [GitLab CI Workflows PoC](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91244)
    - [PoC NPM CI events](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111693)
1. [Proposal 2: Using the `rules` keyword](proposal-2-using-the-rules-keyword.md)
    Highly inefficient way.
1. [Proposal 3: Using the `.gitlab/ci/events` folder](proposal-3-using-the-gitlab-ci-events-folder.md)
    Involves file reading for every event.
1. [Proposal 4: Creating events via a CI config file](proposal-4-creating-events-via-ci-files.md)
    Separate configuration files for defininig events.
1. [Proposal 5: Combined proposal](proposal-5-combined-proposal.md)
    Combination of all of the proposals listed above.
