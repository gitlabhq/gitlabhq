---
status: ongoing
creation-date: "2022-11-25"
authors: [ "@theoretick", "@vbhat161", "@ahmed.hemdan" ]
coach: [ "@theoretick" ]
approvers: [ "@connorgilbert", "@amarpatel" ]
owning-stage: "~devops::secure"
participating-stages: [ "~devops::systems" ]
---

<!-- vale gitlab.FutureTense = NO -->

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

- Support platform-wide detection of tokens to avoid secret leaks
- Prevent exposure by rejecting detected secrets
- Provide scalable means of detection without harming end user experience
- Unified list of token patterns and masking

See [target types](#target-types) for scan target priorities.

### Non-Goals

Phase1 is limited to detection and alerting across platform, with rejection only
during [prereceive Git interactions and browser-based detection](#iterations).

Secret revocation and rotation is also beyond the scope of this new capability.

Scanned object types beyond the scope of this MVC are included within [target types](#target-types).

#### Management UI

Development of an independent interface for managing secrets is out of scope
for this blueprint. Any detections will be managed using the existing
Vulnerability Management UI.

Management of detected secrets will remain distinct from the
[Secret Management feature capability](../../../ci/secrets/index.md) as
"detected" secrets are categorically distinct from actively "managed" secrets.
When a detected secret is identified, it has already been compromised due to
their presence in the target object (that is a repository). Alternatively, managed
secrets should be stored with stricter standards for secure storage, including
encryption and masking when visible (such as job logs or in the UI).

As a long-term priority we should consider unifying the management of the two
secret types however that work is out of scope for the current blueprints goals,
which remain focused on active detection.

### Target types

Target object types refer to the scanning targets prioritized for detection of leaked secrets.

In order of priority this includes:

1. non-binary Git blobs under 1 megabyte
1. job logs
1. issuable creation (issues, MRs, epics)
1. issuable updates (issues, MRs, epics)
1. issuable comments (issues, MRs, epics)

Targets out of scope for the initial phases include:

- non-binary Git blobs over 1 megabyte
- binary Git blobs
- Media types (JPEG, PDF, ...)
- Snippets
- Wikis
- Container images
- External media (Youtube platform videos)

### Token types

The existing Secret Detection configuration covers 100+ rules across a variety
of platforms. To reduce total cost of execution and likelihood of false positives
the dedicated service targets only well-defined, low-FP tokens.

Token types to identify in order of importance:

1. Well-defined GitLab tokens (including Personal Access Tokens and Pipeline Trigger Tokens)
1. Verified Partner tokens (including AWS)
1. Well-defined low-FP third party tokens
1. Remainder tokens currently included in Secret Detection analyzer configuration

A well-defined token is a token with a precise definition, most often a fixed
substring prefix (or suffix) and fixed length.

For GitLab and partner tokens, we have good domain understanding of our own tokens
and by collaborating with partners verified the accuracy of their provided patterns.

An observed low-FP token relies on user reports and dismissal reports. With delivery of
[this data issue](https://gitlab.com/gitlab-data/product-analytics/-/issues/1225)
we will have aggregates on FP-rates but primarily this is user-reported data, at present.

In order to minimize false positives, there are no plans to introduce or alert on high-entropy,
arbitrary strings; i.e. patterns such as `3lsjkw3a22`.

#### Uniformity of rule configuration

Rule pattern configuration should remain centralized in the `secrets` analyzer's packaged `gitleaks.toml`
configuration, vendored to the monolith for Phase 1, and checksum-checked to ensure it matches the
specific release version to avoid drift. Each token can be filtered by `tags` to form both high-confidence
and blocking groupings. For example:

```ruby
prereceive_blocking_rules = toml.load_file('gitleaks.toml')['rules'].select do |r|
  r.tags.include?('gitlab_blocking_p1') &&
    r.tags.include?('gitlab_blocking')
end
```

### Auditability

A critical aspect of both secret detection and [suppression](#detection-suppression) is administrative visibility.
With each phase we must include audit capabilities (events or logging) to enable event discovery.

## Proposal

The first iteration of the experimental capability will feature a blocking
pre-receive hook implemented in the Rails application. This iteration
will be released in an experimental state to select users and provide
opportunity for the team to profile the capability before considering extraction
into a dedicated service.

In the future state, to achieve scalable secret detection for a variety of domain objects a dedicated
scanning service must be created and deployed alongside the GitLab distribution.
This is referred to as the `SecretScanningService`.

This service must be:

- highly performant
- horizontally scalable
- generic in domain object scanning capability

Platform-wide secret detection should be enabled by-default on GitLab SaaS as well
as self-managed instances.

### Decisions

- [001: Use Ruby Push Check approach within monolith](decisions/001_use_ruby_push_check_approach_within_monolith.md)
- [002: Store the Secret Detection Gem in the same repository](decisions/002_store_the_secret_detection_gem_in_the_same_repository.md)
- [003: Run scan within subprocess](decisions/003_run_scan_within_subprocess.md)

## Challenges

- Secure authentication to GitLab.com infrastructure
- Performance of scanning against large blobs
- Performance of scanning against volume of domain objects (such as push frequency)
- Queueing of scan requests

### Transfer optimizations for large Git data blobs

As described in [Gitaly's upload-pack traffic blueprint](../gitaly_handle_upload_pack_in_http2_server/index.md#git-data-transfer-optimization-with-sidechannel), we have faced problems in the past handling large data transfers over gRPC. This could be a concern as we expand secret detection to large blob sizes to increase coverage over leaked secrets. We expect to rollout pre-receive scanning with a 1 megabyte blob size limit which should be well within boundaries. From [Protobuffers' documentation](https://protobuf.dev/programming-guides/techniques/#large-data):

> As a general rule of thumb, if you are dealing in messages larger than a megabyte each, it may be time to consider an alternate strategy.

In expansion phases we must explore chunking or alternative strategies like the optimized sidechannel approach used by Gitaly.

## Design and implementation details

The detection capability relies on a multiphase rollout, from an experimental component implemented directly in the monolith to a standalone service capable of scanning text blobs generically.

The implementation of the secret scanning service is highly dependent on the outcomes of our benchmarking
and capacity planning against both GitLab.com and our
[Reference Architectures](../../../administration/reference_architectures/index.md).
As the scanning capability must be an on-by-default component of both our SaaS and self-managed
instances, [each iteration's](#iterations) deployment characteristic defines whether
the service will act as a standalone component, or executed as a subprocess of the Rails architecture
(as mirrors the implementation of our Elasticsearch indexing service).

See [technical discovery](https://gitlab.com/gitlab-org/gitlab/-/issues/376716)
for further background exploration.

See [this thread](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105142#note_1194863310)
for past discussion around scaling approaches.

### Detection engine

Our current secret detection offering uses [Gitleaks](https://github.com/zricethezav/gitleaks/)
for all secret scanning in pipeline contexts. By using its `--no-git` configuration
we can scan arbitrary text blobs outside of a repository context and continue to
use it for non-pipeline scanning.

Changes to the detection engine are out of scope until benchmarking unveils performance concerns.

For the long-term direction of GitLab Secret Detection, the scope is greater than that of the Gitleaks tool. As such, we should consider feature encapsulation to limit the Gitleaks domain to the relevant build context only.

In the case of pre-receive detection, we rely on a combination of keyword/substring matches
for pre-filtering and `re2` for regex detections. See [spike issue](https://gitlab.com/gitlab-org/gitlab/-/issues/423832) for initial benchmarks.

Notable alternatives include high-performance regex engines such as [Hyperscan](https://github.com/intel/hyperscan) or it's portable fork [Vectorscan](https://github.com/VectorCamp/vectorscan).
These systems may be worth exploring in the future if our performance characteristics show a need to grow beyond the existing stack, however the team's velocity in building an independently scalable and generic scanning engine was prioritized, see [ADR 001](decisions/001_use_ruby_push_check_approach_within_monolith.md) for more on the implementation language considerations.

### Organization-level Controls

Configuration and workflows should be oriented around [Organizations](../organization/index.md). Detection controls and governance patterns should support configuration across multiple projects and groups in a uniform way that emphasizes shared allowlists, organization-wide policies (i.e. disablement of push option bypass), and auditability.

Each phase documents the paradigm used as we iterate from Instance-level to Organization-level controls.

### Phase 1 - Ruby pushcheck pre-receive integration

The critical paths as outlined under [goals above](#goals) cover two major object
types: Git text blobs (corresponding to push events) and arbitrary text blobs. In Phase 1,
we focus entirely on Git text blobs.

The detection flow for push events relies on subscribing to the PreReceive hook
to scan commit data using the [PushCheck interface](https://gitlab.com/gitlab-org/gitlab/blob/3f1653f5706cd0e7bbd60ed7155010c0a32c681d/lib/gitlab/checks/push_check.rb). This `SecretScanningService`
service fetches the specified blob contents from Gitaly, scans
the commit contents, and rejects the push when a secret is detected.
See [Push event detection flow](#push-event-detection-flow) for sequence.

In the case of a push detection, the commit is rejected inline and error returned to the end user.

#### Configuration

This phase will be considered "Experimental" with limited availability for customer opt-in, through instance level application settings.

#### High-Level Architecture

The Phase 1 architecture involves no additional components and is entirely encapsulated in the Rails application server. This provides a rapid deployment with tight integration within auth boundaries and no distribution coordination.

The primary drawback relies on resource utilization, adding additional CPU, memory, transfer volume, and request latency to existing application nodes.

```plantuml
@startuml Phase2
skinparam linetype ortho

card "**External Load Balancer**" as elb #6a9be7

together {
  card "**GitLab Rails**" as gitlab #32CD32
  card "**Gitaly**" as gitaly #FF8C00
  card "**PostgreSQL**" as postgres #4EA7FF
  card "**Redis**" as redis #FF6347
  card "**Sidekiq**" as sidekiq #ff8dd1
}
}

gitlab -[#32CD32]--> gitaly
gitlab -[#32CD32]--> postgres
gitlab -[#32CD32]--> redis
gitlab -[#32CD32]--> sidekiq

elb -[#6a9be7]-> gitlab

gitlab .[#32CD32]----> postgres
sidekiq .[#ff8dd1]----> postgres

@enduml
```

#### Push Event Detection Flow

```mermaid
sequenceDiagram
    autonumber
    actor User
    User->>+Workhorse: git push with-secret
    Workhorse->>+Gitaly: tcp
    Gitaly->>+Rails: PreReceive
    Rails->>-Gitaly: ListAllBlobs
    Gitaly->>-Rails: ListAllBlobsResponse

    Rails->>+GitLabSecretDetection: Scan(blob)
    GitLabSecretDetection->>-Rails: found

    Rails->>User: rejected: secret found

    User->>+Workhorse: git push without-secret
    Workhorse->>+Gitaly: tcp
    Gitaly->>+Rails: PreReceive
    Rails->>-Gitaly: ListAllBlobs
    Gitaly->>-Rails: ListAllBlobsResponse

    Rails->>+GitLabSecretDetection: Scan(blob)
    GitLabSecretDetection->>-Rails: not_found

    Rails->>User: accepted
```

#### Gem Scanning Interface

For the Phase1, we use the private [Secret Detection Ruby Gem](https://gitlab.com/gitlab-org/gitlab/-/tree/5dfcf7431bfff25519c05a7e66c0cbb8d7b362be/gems/gitlab-secret_detection) that is invoked by the [Secrets Push Check](https://gitlab.com/gitlab-org/gitlab/-/blob/5dfcf7431bfff25519c05a7e66c0cbb8d7b362be/ee/lib/gitlab/checks/secrets_check.rb) on the GitLab Rails platform.

The private SD gem offers the following support in addition to running scan on multiple blobs:

- Configurable Timeout on the entire scan-level and on each blob level.

- Ability to run the scan within subprocess instead of the main process. The number of processes spawned per request is capped to [`5`](https://gitlab.com/gitlab-org/gitlab/-/blob/5dfcf7431bfff25519c05a7e66c0cbb8d7b362be/gems/gitlab-secret_detection/lib/gitlab/secret_detection/scan.rb#L29).

The Ruleset file referred during the Pre-receive Secret Detection scan is
located [here](https://gitlab.com/gitlab-org/gitlab/-/blob/2da1c72dbc9df4d9130262c6b79ea785b6bb14ac/gems/gitlab-secret_detection/lib/gitleaks.toml).

More details about the Gem can be found in the [README](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-secret_detection/README.md) file. Also see [ADR 002](decisions/002_store_the_secret_detection_gem_in_the_same_repository.md) for more on how the Gem code is stored and distributed.

### Phase 2 - Standalone pre-receive service

The critical paths as outlined under [goals above](#goals) cover two major object
types: Git text blobs (corresponding to push events) and arbitrary text blobs. In Phase 2,
we continue to focus on Git text blobs.

This phase emphasizes scaling the service outside of the monolith for general availability and to allow
an on-by-default behavior. The architecture is adapted to provide an isolated and independently
scalable service outside of the Rails monolith.

In the case of a push detection, the commit is rejected inline and error returned to the end user.

#### Configuration

This phase will be considered "Generally Available" and on-by-default, with disablement configuration through organization-level settings.

#### High-Level Architecture

The Phase 2 architecture involves extracting the secret detection logic into a standalone service
which communicates directly with both the Rails application and Gitaly. This provides a means to scale
the secret detection nodes independently, and reduce resource usage overhead on the rails application.

Scans still runs synchronously as a (potentially) blocking pre-receive transaction. The blob size remains limited to 1MB.

Note that the node count is purely illustrative, but serves to emphasize the independent scaling requirements for the scanning service.

```plantuml

@startuml Phase2
skinparam linetype ortho

card "**External Load Balancer**" as elb #6a9be7
card "**Internal Load Balancer**" as ilb #9370DB

together {
  collections "**GitLab Rails** x3" as gitlab #32CD32
  collections "**Sidekiq** x3" as sidekiq #ff8dd1
}

together {
  collections "**Consul** x3" as consul #e76a9b
}

card "SecretScanningService Cluster" as prsd_cluster {
  collections "**SecretScanningService** x5" as prsd #FF8C00
}

card "Gitaly Cluster" as gitaly_cluster {
  collections "**Gitaly** x3" as gitaly #FF8C00
}

card "Database" as database {
  collections "**PGBouncer** x3" as pgbouncer #4EA7FF
}

elb -[#6a9be7]-> gitlab

gitlab -[#32CD32,norank]--> ilb
gitlab .[#32CD32]----> database
gitlab -[hidden]-> consul

sidekiq -[#ff8dd1,norank]--> ilb
sidekiq .[#ff8dd1]----> database
sidekiq -[hidden]-> consul

ilb -[#9370DB]--> prsd_cluster
ilb -[#9370DB]--> gitaly_cluster
ilb -[#9370DB]--> database
ilb -[hidden]u-> consul

consul .[#e76a9b]u-> gitlab
consul .[#e76a9b]u-> sidekiq
consul .[#e76a9b]-> database
consul .[#e76a9b]-> gitaly_cluster
consul .[#e76a9b]-> prsd_cluster

@enduml
```

#### Push Event Detection Flow

```mermaid
sequenceDiagram
    autonumber
    actor User
    User->>+Workhorse: git push with-secret
    Workhorse->>+Gitaly: tcp
    Gitaly->>+GitLabSecretDetection: PreReceive
    GitLabSecretDetection->>-Gitaly: ListAllBlobs
    Gitaly->>-GitLabSecretDetection: ListAllBlobsResponse

    Gitaly->>+GitLabSecretDetection: PreReceive

    GitLabSecretDetection->>GitLabSecretDetection: Scan(blob)
    GitLabSecretDetection->>-Gitaly: found

    Gitaly->>+Rails: PreReceive

    Rails->>User: rejected: secret found

    User->>+Workhorse: git push without-secret
    Workhorse->>+Gitaly: tcp
    Gitaly->>+GitLabSecretDetection: PreReceive
    GitLabSecretDetection->>-Gitaly: ListAllBlobs
    Gitaly->>-GitLabSecretDetection: ListAllBlobsResponse

    Gitaly->>+GitLabSecretDetection: PreReceive

    GitLabSecretDetection->>GitLabSecretDetection: Scan(blob)
    GitLabSecretDetection->>-Gitaly: not_found

    Gitaly->>+Rails: PreReceive

    Rails->>User: accepted
```

### Phase 3 - Expansion beyond pre-receive service

The detection flow for arbitrary text blobs, such as issue comments, relies on
subscribing to `Notes::PostProcessService` (or equivalent service) to enqueue
Sidekiq requests to the `SecretScanningService` to process the text blob by object type
and primary key of domain object. The `SecretScanningService` service fetches the
relevant text blob, scans the contents, and notifies the Rails application when a secret
is detected.

The detection flow for job logs requires processing the log during archive to object
storage. See discussion [in this issue](https://gitlab.com/groups/gitlab-org/-/epics/8847#note_1116647883)
around scanning during streaming and the added complexity in buffering lookbacks
for arbitrary trace chunks.

In the case of a push detection, the commit is rejected and error returned to the end user.
In any other case of detection, the Rails application manually creates a vulnerability
using the `Vulnerabilities::ManuallyCreateService` to surface the finding in the
existing Vulnerability Management UI.

#### Configuration

This phase will be considered "Generally Available" and on-by-default, with disablement configuration through organization-level settings.

#### High-Level Architecture

There is no change to the architecture defined in Phase 2, however the individual load requirements may require scaling up the node counts for the detection service.

#### Push Event Detection Flow

There is no change to the push event detection flow defined in Phase 2, however the added capability to scan
arbitary text blobs directly from Rails allows us to emulate a pre-receive behavior for issuable creations,
as well (see [target types](#target-types) for priority object types).

```mermaid
sequenceDiagram
    autonumber
    actor User
    User->>+Workhorse: git push with-secret
    Workhorse->>+Gitaly: tcp
    Gitaly->>+GitLabSecretDetection: PreReceive
    GitLabSecretDetection->>-Gitaly: ListAllBlobs
    Gitaly->>-GitLabSecretDetection: ListAllBlobsResponse

    Gitaly->>+GitLabSecretDetection: PreReceive

    GitLabSecretDetection->>GitLabSecretDetection: Scan(blob)
    GitLabSecretDetection->>-Gitaly: found

    Gitaly->>+Rails: PreReceive

    Rails->>User: rejected: secret found

    User->>+Workhorse: POST issuable with-secret
    Workhorse->>+Rails: tcp
    Rails->>+GitLabSecretDetection: PreReceive

    GitLabSecretDetection->>GitLabSecretDetection: Scan(blob)
    GitLabSecretDetection->>-Rails: found

    Rails->>User: rejected: secret found
```

### Future Phases

These are key items for delivering a feature-complete always-on experience but have not have yet been prioritized into phases.

### Large blob sizes (1mb+)

Current phases do not include expansions of blob sizes beyond 1mb. While the main limitation was chosen [to conform to RPC transfer limits for future iterations](#transfer-optimizations-for-large-git-data-blobs) we should expand to supporting additional blob sizes. This can be achieved in two ways:

1. *Post-receive processing*

    Accept blobs in a non-blocking fashion, process scanning as background job and alert passively on detection of a given secret.

1. *Improvements to scanning logic batching*

    Maintaining the constraint of 1MB is primarily futureproofing to match an expected transport protocol. This can be mitigated by using separate transport (http, reads from disk, ...) or by slicing blob sizes.

### Detection Suppression

Suppression of detection and action on leaked secrets will be supported at several levels.

1. *Global suppression* - If a secret is highly-likely to be a false token (i.e. `EXAMPLE`) it should be suppressed in workflow contexts where user would be seriously inconvenienced.

    We should still provide some means of triaging these results, whether via [audit events](#auditability) or as [automatic vulnerability resolution](../../../user/application_security/sast/index.md#automatic-vulnerability-resolution).

1. *Organization suppression* - If a secret matches an organization's allowlist (or was previously flagged and remediated as irrelevant) it should not reoccur. See [Organization-level controls](#organization-level-controls).

1. *Inline suppression* - Inline annotations should be supported in later phases with the Organization-level configuration to ignore annotations.

### External Token Verification

As a post-processing step for detection we should explore verification of detected secrets. This requires processors per supported token type in which we can distinguish tokens that are valid leaks from false positives. Similar to our [automatic response to leaked secrets](../../../user/application_security/secret_detection/automatic_response.md), we must externally verify a given token to give a high degree of confidence in our alerting.

There are two token types: internal and external:

- Internal tokens are verifiable and revocable as part of `ScanSecurityReportSecretsWorker` worker
- External tokens require external verification, in which [the architecture](../../../user/application_security/secret_detection/automatic_response.md#high-level-architecture) will closely match the [Secret Revocation Service](https://gitlab.com/gitlab-com/gl-security/engineering-and-research/automation-team/secret-revocation-service/)

## Iterations

- ✓ Define [requirements for detection coverage and actions](https://gitlab.com/gitlab-org/gitlab/-/issues/376716)
- ✓ Implement [Browser-based detection of GitLab tokens in comments/issues](https://gitlab.com/gitlab-org/gitlab/-/issues/368434)
- ✓ [PoC of secret scanning service](https://gitlab.com/gitlab-org/secure/pocs/secret-detection-go-poc/)
- ✓ [PoC of secret scanning gem](https://gitlab.com/gitlab-org/gitlab/-/issues/426823)
- [Pre-Production Performance Profiling for pre-receive PoCs](https://gitlab.com/gitlab-org/gitlab/-/issues/428499)
  - Profiling service capabilities
    - ✓ [Benchmarking regex performance between Ruby and Go approaches](https://gitlab.com/gitlab-org/gitlab/-/issues/423832)
    - transfer latency, CPU, and memory footprint
- ✓ Implementation of secret scanning gem integration MVC (targeting individual commits)
- Phase1 - Deployment and monitoring
- Capacity planning for addition of service component to Reference Architectures headroom
- Security and readiness review
- Phase2 - Deployment and monitoring
- Implementation of secret scanning service (targeting arbitrary text blobs)
- Phase3 - Deployment and monitoring
- High priority domain object rollout (priority `TBD`)
  - Issuable comments
  - Issuable bodies
  - Job logs
