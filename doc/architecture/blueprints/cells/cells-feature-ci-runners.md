---
stage: enablement
group: Tenant Scale
description: 'Cells: CI Runners'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: CI Runners

GitLab in order to execute CI jobs [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/),
very often managed by customer in their infrastructure.

All CI jobs created as part of CI pipeline are run in a context of project
it poses a challenge how to manage GitLab Runners.

## 1. Definition

There are 3 different types of runners:

- instance-wide: runners that are registered globally with specific tags (selection criteria)
- group runners: runners that execute jobs from a given top-level group or subprojects of that group
- project runners: runners that execute jobs from projects or many projects: some runners might
  have projects assigned from projects in different top-level groups.

This alongside with existing data structure where `ci_runners` is a table describing
all types of runners poses a challenge how the `ci_runners` should be managed in a Cells environment.

## 2. Data flow

GitLab Runners use a set of globally scoped endpoints to:

- registration of a new runner via registration token `https://gitlab.com/api/v4/runners`
  ([subject for removal](../runner_tokens/index.md)) (`registration token`)
- requests jobs via an authenticated `https://gitlab.com/api/v4/jobs/request` endpoint (`runner token`)
- upload job status via `https://gitlab.com/api/v4/jobs/:job_id` (`build token`)
- upload trace via `https://gitlab.com/api/v4/jobs/:job_id/trace` (`build token`)
- download and upload artifacts via `https://gitlab.com/api/v4/jobs/:job_id/artifacts` (`build token`)

Currently three types of authentication tokens are used:

- runner registration token ([subject for removal](../runner_tokens/index.md))
- runner token representing an registered runner in a system with specific configuration (`tags`, `locked`, etc.)
- build token representing an ephemeral token giving a limited access to updating a specific
  job, uploading artifacts, downloading dependent artifacts, downloading and uploading
  container registry images

Each of those endpoints do receive an authentication token via header (`JOB-TOKEN` for `/trace`)
or body parameter (`token` all other endpoints).

Since the CI pipeline would be created in a context of a specific Cell it would be required
that pick of a build would have to be processed by that particular Cell. This requires
that build picking depending on a solution would have to be either:

- routed to correct Cell for a first time
- be made to be two phase: request build from global pool, claim build on a specific Cell using a Cell specific URL

## 3. Proposal

This section describes various proposals. Reader should consider that those
proposals do describe solutions for different problems. Many or some aspects
of those proposals might be the solution to the stated problem.

### 3.1. Authentication tokens

Even though the paths for CI Runners are not routable they can be made routable with
those two possible solutions:

- The `https://gitlab.com/api/v4/jobs/request` uses a long polling mechanism with
  a ticketing mechanism (based on `X-GitLab-Last-Update` header). Runner when first
  starts sends a request to GitLab to which GitLab responds with either a build to pick
  by runner. This value is completely controlled by GitLab. This allows GitLab
  to use JWT or any other means to encode `cell` identifier that could be easily
  decodable by Router.
- The majority of communication (in terms of volume) is using `build token` making it
  the easiest target to change since GitLab is sole owner of the token that Runner later
  uses for specific job. There were prior discussions about not storing `build token`
  but rather using `JWT` token with defined scopes. Such token could encode the `cell`
  to which router could easily route all requests.

### 3.2. Request body

- The most of used endpoints pass authentication token in request body. It might be desired
  to use HTTP Headers as an easier way to access this information by Router without
  a need to proxy requests.

### 3.3. Instance-wide are Cell local

We can pick a design where all runners are always registered and local to a given Cell:

- Each Cell has it's own set of instance-wide runners that are updated at it's own pace
- The project runners can only be linked to projects from the same organization
  creating strong isolation.
- In this model the `ci_runners` table is local to the Cell.
- In this model we would require the above endpoints to be scoped to a Cell in some way
  or made routable. It might be via prefixing them, adding additional Cell parameter,
  or providing much more robust way to decode runner token and match it to Cell.
- If routable token is used, we could move away from cryptographic random stored in
  database to rather prefer to use JWT tokens that would encode
- The Admin Area showing registered Runners would have to be scoped to a Cell

This model might be desired since it provides strong isolation guarantees.
This model does significantly increase maintenance overhead since each Cell is managed
separately.

This model may require adjustments to runner tags feature so that projects have consistent runner experience across cells.

### 3.4. Instance-wide are cluster-wide

Contrary to proposal where all runners are Cell local, we can consider that runners
are global, or just instance-wide runners are global.

However, this requires significant overhaul of system and to change the following aspects:

- `ci_runners` table would likely have to be split decomposed into `ci_instance_runners`, ...
- all interfaces would have to be adopted to use correct table
- build queuing would have to be reworked to be two phase where each Cell would know of all pending
  and running builds, but the actual claim of a build would happen against a Cell containing data
- likely `ci_pending_builds` and `ci_running_builds` would have to be made `cluster-wide` tables
  increasing likelihood of creating hotspots in a system related to CI queueing

This model makes it complex to implement from engineering side. Does make some data being shared
between Cells. Creates hotspots / scalability issues in a system (ex. during abuse) that
might impact experience of organizations on other Cells.

### 3.5. GitLab CI Daemon

Another potential solution to explore is to have a dedicated service responsible for builds queueing
owning it's database and working in a model of either sharded or celled service. There were prior
discussions about [CI/CD Daemon](https://gitlab.com/gitlab-org/gitlab/-/issues/19435).

If the service would be sharded:

- depending on a model if runners are cluster-wide or cell-local this service would have to fetch
  data from all Cells
- if the sharded service would be used we could adapt a model of either sharing database containing
  `ci_pending_builds/ci_running_builds` with the service
- if the sharded service would be used we could consider a push model where each Cell pushes to CI/CD Daemon
  builds that should be picked by Runner
- the sharded service would be aware which Cell is responsible for processing the given build and could
  route processing requests to designated Cell

If the service would be celled:

- all expectations of routable endpoints are still valid

In general usage of CI Daemon does not help significantly with the stated problem. However, this offers
a few upsides related to more efficient processing and decoupling model: push model and it opens a way
to offer stateful communication with GitLab Runners (ex. gRPC or Websockets).

## 4. Evaluation

Considering all solutions it appears that solution giving the most promise is:

- use "instance-wide are Cell local"
- refine endpoints to have routable identities (either via specific paths, or better tokens)

Other potential upsides is to get rid of `ci_builds.token` and rather use a `JWT token`
that can much better and easier encode wider set of scopes allowed by CI runner.

## 4.1. Pros

## 4.2. Cons
