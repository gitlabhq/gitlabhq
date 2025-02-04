---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Adding new features to Workhorse
---

GitLab Workhorse is a smart reverse proxy for GitLab. It handles
[long HTTP requests](#what-are-long-requests), such as:

- File downloads.
- File uploads.
- Git pushes and pulls.
- Git archive downloads.

Workhorse itself is not a feature, but [several features in GitLab](gitlab_features.md)
would not work efficiently without Workhorse.

At a first glance, Workhorse appears to be just a pipeline for processing HTTP
streams to reduce the amount of logic in your Ruby on Rails controller. However,
don't treat it that way. Engineers trying to offload a feature to Workhorse often
find it takes more work than originally anticipated:

- It's a new programming language, and only a few engineers at GitLab are Go developers.
- Workhorse has demanding requirements:
  - It's stateless.
  - Memory and disk usage must be kept under tight control.
  - The request should not be slowed down in the process.

## Avoid adding new features

We suggest adding new features only if absolutely necessary and no other options exist.
Splitting a feature between the Rails codebase and Workhorse is a deliberate choice
to introduce technical debt. It adds complexity to the system, and coupling between
the two components:

- Building features using Workhorse has a considerable complexity cost, so you should
  prefer designs based on Rails requests and Sidekiq jobs.
- Even when using Rails-and-Sidekiq is more work than using Rails-and-Workhorse,
  Rails-and-Sidekiq is easier to maintain in the long term. Workhorse is unique
  to GitLab, while Rails-and-Sidekiq is an industry standard.
- For global behaviors around web requests, consider using a Rack middleware
  instead of Workhorse.
- Generally speaking, use Rails-and-Workhorse only if the HTTP client expects
  behavior reasonable to implement in Rails, like long requests.

## What are long requests?

One order of magnitude exists between Workhorse and Puma RAM usage. Having a connection
open for longer than milliseconds is problematic due to the amount of RAM
it monopolizes after it reaches the Ruby on Rails controller. We've identified two classes
of long requests: data transfers and HTTP long polling. Some examples:

- `git push`.
- `git pull`.
- Uploading or downloading an artifact.
- A CI runner waiting for a new job.

With the rise of cloud-native installations, Workhorse's feature set was extended
to add object storage direct-upload. This change removed the need for the shared
Network File System (NFS) drives.

If you still think we should add a new feature to Workhorse, open an issue for the
Workhorse maintainers and explain:

1. What you want to implement.
1. Why it can't be implemented in our Ruby codebase.

The Workhorse maintainers can help you assess the situation.

## Related topics

- In 2020, `@nolith` presented the talk
  ["Speed up the monolith. Building a smart reverse proxy in Go"](https://archive.fosdem.org/2020/schedule/event/speedupmonolith/)
  at FOSDEM. The talk includes more details on the history of Workhorse and the NFS removal.
- The [uploads development documentation](../uploads/_index.md) contains the most common
  use cases for adding a new type of upload.
