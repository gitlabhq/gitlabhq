---
status: proposed
creation-date: 2022-11-25
authors: [ "@theoretick" ]
coach: "@DylanGriffith"
approvers: [ "@connorgilbert", "@amarpatel" ]
owning-stage: "~devops::secure"
participating-stages: []
---

# Secret Detection as a platform-wide experience

## Summary

Today's secret detection feature is built around containerized scans of repositories
within a pipeline context. This feature is quite limited compared to where leaks
or compromised tokens may appear and should be expanded to include a much wider scope.

Secret detection as a platform-wide experience encompasses detection across
platform features with high risk of secret leakage, including repository contents,
job logs, and project management features such as issues, epics, and MRs.

## Motivation

### Goals

- Support asynchronous secret detection for:
  - push events
  - issuable creation
  - issuable updates
  - issuable comments

### Non-Goals

The current proposal is limited to asynchronous detection and alerting only.

**Blocking** secrets on push events is high-risk to a critical path and
would require extensive performance profiling before implementing. See
[a recent example](https://gitlab.com/gitlab-org/gitlab/-/issues/246819#note_1164411983)
of a customer incident where this was attempted.

Secret revocation and rotation is also beyond the scope of this new capability.

Scanned object types beyond the scope of this MVC include:

- Media types (JPEGs, PDFs,...)
- Snippets
- Wikis

## Proposal

To achieve scalable secret detection for a variety of domain objects a dedicated
scanning service must be created and deployed alongside the GitLab distribution.
This is referred to as the `SecretScanningService`.

This service must be:

- highly performant
- horizontally scalable
- generic in domain object scanning capability

Platform-wide secret detection should be enabled by-default on GitLab SaaS as well
as self-managed instances.

## Challenges

- Secure authentication to GitLab.com infrastructure
- Performance of scanning against large blobs
- Performance of scanning against volume of domain objects (such as push frequency)

## Design and implementation details

The critical paths as outlined under [goals above](#goals) cover two major object
types: Git blobs (corresponding to push events) and arbitrary text blobs.

The detection flow for push events relies on subscribing to the PostReceive hook
and enqueueing Sidekiq requests to the `SecretScanningService`. The `SecretScanningService`
service fetches enqueued refs, queries Gitaly for the ref blob contents, scans
the commit contents, and notifies the Rails application when a secret is detected.
See [Push event detection flow](#push-event-detection-flow) for sequence.

The detection flow for arbitrary text blobs, such as issue comments, relies on
subscribing to `Notes::PostProcessService` (or equivalent service) and enqueueing
Sidekiq requests to the `SecretScanningService` to process the text blob by object type
and primary key of domain object. The `SecretScanningService` service fetches the
relevant text blob, scans the contents, and notifies the Rails application when a secret
is detected.

The detection flow for job logs requires processing the log during archive to object
storage. See discussion [in this issue](https://gitlab.com/groups/gitlab-org/-/epics/8847#note_1116647883)
around scanning during streaming and the added complexity in buffering lookbacks
for arbitrary trace chunks.

In any case of detection, the Rails application manually creates a vulnerability
using the `Vulnerabilities::ManuallyCreateService` to surface the finding within the
existing Vulnerability Management UI.

See [technical discovery](https://gitlab.com/gitlab-org/gitlab/-/issues/376716)
for further background exploration.

### Token types

The existing Secret Detection configuration covers ~100 rules across a variety
of platforms. To reduce total cost of execution and likelihood of false positives
the dedicated service targets only well-defined tokens. A well-defined token is
defined as a token with a precise definition, most often a fixed substring prefix or
suffix and fixed length.

Token types to identify in order of importance:

1. Well-defined GitLab tokens (including Personal Access Tokens and Pipeline Trigger Tokens)
1. Verified Partner tokens (including AWS)
1. Remainder tokens currently included in Secret Detection CI configuration

### Detection engine

Our current secret detection offering utilizes [Gitleaks](https://github.com/zricethezav/gitleaks/)
for all secret scanning within pipeline contexts. By using its `--no-git` configuration
we can scan arbitrary text blobs outside of a repository context and continue to
utilize it for non-pipeline scanning.

Given our existing familiarity with the tool and its extensibility, it should
remain our engine of choice. Changes to the detection engine are out of scope
unless benchmarking unveils performance concerns.

### Push event detection flow

```mermaid
sequenceDiagram
    autonumber
    actor User
    User->>+Workhorse: git push
    Workhorse->>+Gitaly: tcp
    Gitaly->>+Rails: grpc
    Sidekiq->>+Rails: poll job
    Rails->>-Sidekiq: PostReceive worker
    Sidekiq-->>+Sidekiq: enqueue PostReceiveSecretScanWorker

    Sidekiq->>+Rails: poll job
    loop PostReceiveSecretScanWorker
      Rails->>-Sidekiq: PostReceiveSecretScanWorker
      Sidekiq->>+SecretScanningSvc: ScanBlob(ref)
      SecretScanningSvc->>+Sidekiq: accepted
      Note right of SecretScanningSvc: Scanning job enqueued
      Sidekiq-->>+Rails: done
      SecretScanningSvc->>+Gitaly: retrieve blob
      SecretScanningSvc->>+SecretScanningSvc: scan blob
      SecretScanningSvc->>+Rails: secret found
    end
```

## Iterations

1. Requirements definition for detection coverage and actions
1. PoC of secret scanning service
    1. gRPC commit retrieval from Gitaly
    1. blob scanning
    1. benchmarking of issuables, comments, job logs and blobs to gain confidence that the total costs will be viable
1. Implementation of secret scanning service MVC (targeting individual commits)
1. Security and readiness review
1. Deployment and monitoring
1. Implementation of secret scanning service MVC (targeting arbitrary text blobs)
1. Deployment and monitoring
1. High priority domain object rollout (priority `TBD`)
    1. Issuable comments
    1. Issuable bodies
    1. Job logs
