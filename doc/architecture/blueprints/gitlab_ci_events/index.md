---
status: proposed
creation-date: "2023-03-15"
authors: [ "@furkanayhan" ]
coach: "@grzesiek"
approvers: [ "@jreporter", "@cheryl.li" ]
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

## Proposals

For now, we have technical 4 proposals;

1. [Proposal 1: Using the `.gitlab-ci.yml` file](proposal-1-using-the-gitlab-ci-file.md)
    Based on;
    - [GitLab CI Workflows PoC](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91244)
    - [PoC NPM CI events](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111693)
1. [Proposal 2: Using the `rules` keyword](proposal-2-using-the-rules-keyword.md)
    Highly inefficient way.
1. [Proposal 3: Using the `.gitlab/ci/events` folder](proposal-3-using-the-gitlab-ci-events-folder.md)
    Involves file reading for every event.
1. [Proposal 4: Creating events via CI files](proposal-4-creating-events-via-ci-files.md)
    Combination of some proposals.

Each of them has its pros and cons. There could be many more proposals and we
would like to discuss them all. We can combine the best part of those proposals
and create a new one.
