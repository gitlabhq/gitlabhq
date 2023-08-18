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

GitLab executes CI jobs via [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/), very often managed by customers in their infrastructure.
All CI jobs created as part of the CI pipeline are run in the context of a Project.
This poses a challenge how to manage GitLab Runners.

## 1. Definition

There are 3 different types of runners:

- Instance-wide: Runners that are registered globally with specific tags (selection criteria)
- Group runners: Runners that execute jobs from a given top-level Group or Projects in that Group
- Project runners: Runners that execute jobs from one Projects or many Projects: some runners might
  have Projects assigned from Projects in different top-level Groups.

This, alongside with the existing data structure where `ci_runners` is a table describing all types of runners, poses a challenge as to how the `ci_runners` should be managed in a Cells environment.

## 2. Data flow

GitLab runners use a set of globally scoped endpoints to:

- Register a new runner via registration token `https://gitlab.com/api/v4/runners`
  ([subject for removal](../../runner_tokens/index.md)) (`registration token`)
- Create a new runner in the context of a user `https://gitlab.com/api/v4/user/runners` (`runner token`)
- Request jobs via an authenticated `https://gitlab.com/api/v4/jobs/request` endpoint (`runner token`)
- Upload job status via `https://gitlab.com/api/v4/jobs/:job_id` (`build token`)
- Upload trace via `https://gitlab.com/api/v4/jobs/:job_id/trace` (`build token`)
- Download and upload artifacts via `https://gitlab.com/api/v4/jobs/:job_id/artifacts` (`build token`)

Currently three types of authentication tokens are used:

- Runner registration token ([subject for removal](../../runner_tokens/index.md))
- Runner token representing a registered runner in a system with specific configuration (`tags`, `locked`, etc.)
- Build token representing an ephemeral token giving limited access to updating a specific job, uploading artifacts, downloading dependent artifacts, downloading and uploading container registry images

Each of those endpoints receive an authentication token via header (`JOB-TOKEN` for `/trace`) or body parameter (`token` all other endpoints).

Since the CI pipeline would be created in the context of a specific Cell, it would be required that pick of a build would have to be processed by that particular Cell.
This requires that build picking depending on a solution would have to be either:

- Routed to the correct Cell for the first time
- Be two-phased: Request build from global pool, claim build on a specific Cell using a Cell specific URL

## 3. Proposal

### 3.1. Authentication tokens

Even though the paths for CI runners are not routable, they can be made routable with these two possible solutions:

- The `https://gitlab.com/api/v4/jobs/request` uses a long polling mechanism with
  a ticketing mechanism (based on `X-GitLab-Last-Update` header). When the runner first
  starts, it sends a request to GitLab to which GitLab responds with either a build to pick
  by runner. This value is completely controlled by GitLab. This allows GitLab
  to use JWT or any other means to encode a `cell` identifier that could be easily
  decodable by Router.
- The majority of communication (in terms of volume) is using `build token`, making it
  the easiest target to change since GitLab is the sole owner of the token that the runner later
  uses for a specific job. There were prior discussions about not storing the `build token`
  but rather using a `JWT` token with defined scopes. Such a token could encode the `cell`
  to which the Router could route all requests.

### 3.2. Request body

- The most used endpoints pass the authentication token in the request body. It might be desired
  to use HTTP headers as an easier way to access this information by Router without
  a need to proxy requests.

### 3.3. Instance-wide are Cell-local

We can pick a design where all runners are always registered and local to a given Cell:

- Each Cell has its own set of instance-wide runners that are updated at its own pace
- The Project runners can only be linked to Projects from the same Organization, creating strong isolation.
- In this model the `ci_runners` table is local to the Cell.
- In this model we would require the above endpoints to be scoped to a Cell in some way, or be made routable. It might be via prefixing them, adding additional Cell parameters, or providing much more robust ways to decode runner tokens and match it to a Cell.
- If a routable token is used, we could move away from cryptographic random stored in database to rather prefer to use JWT tokens.
- The Admin Area showing registered runners would have to be scoped to a Cell.

This model might be desired because it provides strong isolation guarantees.
This model does significantly increase maintenance overhead because each Cell is managed separately.
This model may require adjustments to the runner tags feature so that Projects have a consistent runner experience across Cells.

### 3.4. Instance-wide are cluster-wide

Contrary to the proposal where all runners are Cell-local, we can consider that runners
are global, or just instance-wide runners are global.

However, this requires significant overhaul of the system and we would have to change the following aspects:

- The `ci_runners` table would likely have to be decomposed into `ci_instance_runners`, ...
- All interfaces would have to be adopted to use the correct table.
- Build queuing would have to be reworked to be two-phased where each Cell would know of all pending and running builds, but the actual claim of a build would happen against a Cell containing data.
- It is likely that `ci_pending_builds` and `ci_running_builds` would have to be made `cluster-wide` tables, increasing the likelihood of creating hotspots in a system related to CI queueing.

This model is complex to implement from an engineering perspective.
Some data are shared between Cells.
It creates hotspots/scalability issues in a system that might impact the experience of Organizations on other Cells, for instance during abuse.

### 3.5. GitLab CI Daemon

Another potential solution to explore is to have a dedicated service responsible for builds queueing, owning its database and working in a model of either sharded or Cell-ed service.
There were prior discussions about [CI/CD Daemon](https://gitlab.com/gitlab-org/gitlab/-/issues/19435).

If the service is sharded:

- Depending on the model, if runners are cluster-wide or Cell-local, this service would have to fetch data from all Cells.
- If the sharded service is used we could adapt a model of sharing a database containing `ci_pending_builds/ci_running_builds` with the service.
- If the sharded service is used we could consider a push model where each Cell pushes to CI/CD Daemon builds that should be picked by runner.
- The sharded service would be aware which Cell is responsible for processing the given build and could route processing requests to the designated Cell.

If the service is Cell-ed:

- All expectations of routable endpoints are still valid.

In general usage of CI Daemon does not help significantly with the stated problem.
However, this offers a few upsides related to more efficient processing and decoupling model: push model and it opens a way to offer stateful communication with GitLab runners (ex. gRPC or Websockets).

## 4. Evaluation

Considering all options it appears that the most promising solution is to:

- Use [Instance-wide are Cell-local](#33-instance-wide-are-cell-local)
- Refine endpoints to have routable identities (either via specific paths, or better tokens)

Another potential upside is to get rid of `ci_builds.token` and rather use a `JWT token` that can much better and easier encode a wider set of scopes allowed by CI runner.

## 4.1. Pros

## 4.2. Cons
