---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Managing Go versions
---

## Overview

All Go binaries, with the exception of
[GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner) and [Security Projects](https://gitlab.com/gitlab-org/security-products), are built in
projects managed by the [Distribution team](https://handbook.gitlab.com/handbook/product/categories/#distribution-group).

The [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab) project creates a
single, monolithic operating system package containing all the binaries, while
the [Cloud-Native GitLab (CNG)](https://gitlab.com/gitlab-org/build/CNG) project
publishes a set of Docker images deployed and configured by Helm Charts or
the GitLab Operator.

## Testing against shipped Go versions

Testing matrices for all projects using Go must include the version shipped by Distribution. Check the Go version set by `GO_VERSION` for:

- [Linux package builds](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/blob/master/docker/VERSIONS).
- [Cloud-Native GitLab (CNG)](https://gitlab.com/gitlab-org/build/cng/blob/master/ci_files/variables.yml).

## Supporting multiple Go versions

Individual Go projects need to support multiple Go versions because:

- When a new version of Go is released, we should start integrating it into the CI pipelines to verify compatibility with the new compiler.
- We must support the versions of Go [shipped by Distribution](#testing-against-shipped-go-versions), which might be behind the latest minor release.
- When Linux package builds or Cloud-Native GitLab (CNG) change a Go version, we still might need to support the old version for backports.

These 3 requirements may easily be satisfied by keeping support for the [3 latest minor versions of Go](https://go.dev/dl/).

It is ok to drop support for the oldest Go version and support only the 2 latest releases,
if this is enough to support backports to the last 3 minor GitLab releases.

For example, if we want to drop support for `go 1.11` in GitLab `12.10`, we need
to verify which Go versions we are using in `12.9`, `12.8`, and `12.7`. We do not
consider the active milestone, `12.10`, because a backport for `12.7` is required
in case of a critical patch release.

- If both [Omnibus GitLab and Cloud-Native GitLab (CNG)](#updating-go-version) were using Go `1.12` in GitLab `12.7` and later,
  then we can safely drop support for `1.11`.
- If Omnibus GitLab or Cloud-Native GitLab (CNG) were using `1.11` in GitLab `12.7`, then we still need to keep
  support for Go `1.11` for easier backporting of security fixes.

## Updating Go version

We should always:

- Use the same Go version for Omnibus GitLab and Cloud Native GitLab.
- Use a [supported version](https://go.dev/doc/devel/release#policy).
- Use the most recent patch-level for that version to keep up with security fixes.

Changing the version affects every project being compiled, so it's important to
ensure that all projects have been updated to test against the new Go version
before changing the package builders to use it. Despite [Go's compatibility promise](https://go.dev/doc/go1compat),
changes between minor versions can expose bugs or cause problems in our projects.

### Upgrade cadence

GitLab adopts major Go versions within eight months of their release
to ensure supported GitLab versions do not ship with an end-of-life
version of Go.

Minor upgrades are required if they patch security issues, fix bugs, or add
features requested by development teams and are approved by Product Management.

For more information, see:

- [The Go release cycle](https://go.dev/wiki/Go-Release-Cycle).
- [The Go release policy](https://go.dev/doc/devel/release#policy).

### Upgrade process

The upgrade process involves several key steps:

- [Track component updates and validation](#tracking-work).
- [Track component integration for release](#tracking-work).
- [Communication with stakeholders](#communication-plan).

#### Tracking work

Use [the product categories page](https://handbook.gitlab.com/handbook/product/categories/)
if you need help finding the correct person or labels:

1. Create the epic in `gitlab-org` group:
   - Title the epic `Update Go version to <VERSION_NUMBER>`.
   - Ping the engineering managers responsible for [the projects listed below](#known-dependencies-using-go).
     - Most engineering managers can be identified on
       [the product page](https://handbook.gitlab.com/handbook/product/categories/) or the
       [feature page](https://handbook.gitlab.com/handbook/product/categories/features/).
     - If you still can't find the engineering manager, use
       [Git blame](../../user/project/repository/files/git_blame.md) to identify a maintainer
       involved in the project.

1. Create an upgrade issue for each dependency in the
   [location indicated below](#known-dependencies-using-go) titled
   `Support building with Go <VERSION_NUMBER>`. Add the proper labels to each issue
   for easier triage. These should include the stage, group and section.
   - The issue should be assigned by a member of the maintaining group.
   - The milestone should be assigned by a member of the maintaining group.

   NOTE:
   Some overlap exists between project dependencies. When creating an issue for a
   dependency that is part of a larger product, note the relationship in the issue
   body. For example: Projects built in the context of Omnibus GitLab have their
   runtime Go version managed by Omnibus, but "support" and compatibility should
   be a concern of the individual project. Issues in the parent project's dependencies
   issue should be about adding support for the updated Go version.

   NOTE:
   The upgrade issues must include [upgrade validation items](#upgrade-validation)
   in their definition of done. Creating a second [performance testing issue](#upgrade-validation)
   titled `Validate operation and performance at scale with Go <VERSION_NUMBER>`
   is strongly recommended to help with scheduling tasks and managing workloads.

1. Schedule an update with the [GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues):
   - Title the issue `Support using Go version <VERSION_NUMBER>`.
   - Set the issue as related to every issue created in the previous step.
1. Schedule one issue per Sec Section team that maintains Go based Security Analyzers and add the `section::sec` label to each:
   - [Static Analysis tracker](https://gitlab.com/gitlab-org/gitlab/-/issues).
   - [Composition Analysis tracker](https://gitlab.com/gitlab-org/gitlab/-/issues).
   - [Container Security tracker](https://gitlab.com/gitlab-org/gitlab/-/issues).

   NOTE:
   Updates to these Security analyzers should not block upgrades to Charts or Omnibus since
   the analyzers are built independently as separate container images.

1. Schedule builder updates with Distribution projects:
   - Dependency and GitLab Development Kit issues created in previous steps should be set as blockers.
   - Each issue should have the title `Support building with Go <VERSION_NUMBER>` and description as noted:
     - [Cloud-Native GitLab](https://gitlab.com/gitlab-org/charts/gitlab/-/issues)

       ```plaintext
       Update the `GO_VERSION` in `ci_files/variables.yml`.
       ```

     - [Omnibus GitLab Builder](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/issues)

       ```plaintext
       Update `GO_VERSION` in `docker/VERSIONS`.
       ```

     - [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues)

       ```plaintext
       Update `BUILDER_IMAGE_REVISION` in `.gitlab-ci.yml` to match tag from builder.
       ```

   NOTE:
   If the component is not automatically upgraded for [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues)
   and [Cloud Native GitLab](https://gitlab.com/gitlab-org/charts/gitlab/-/issues),
   issues should be opened in their respective trackers titled `Updated bundled version of COMPONENT_NAME`
   and set as blocked by the component's upgrade issue.

#### Known dependencies using Go

The directly responsible individual for a Go upgrade must ensure all
necessary components get upgraded.

##### Prerequisites

These projects must be upgraded first and in the order they appear to allow
projects listed in the next section to build with the newer Go version.

| Component Name                                                                   | Where to track work                                                                                                |
|----------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| GitLab Runner                                                                    | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab-runner)                                                       |
| GitLab CI Images                                                                 | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab-build-images/-/issues)                                        |
| GitLab Development Kit (GDK)                                                     | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab-development-kit)                                              |

##### Required for release approval

Major Go release versions require updates to each project listed below
to allow the version to flow into their build jobs. Each project must build
successfully before the actual build environments get updates.

| Component Name                                                                   | Where to track work                                                                                                |
|----------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| [Alertmanager](https://github.com/prometheus/alertmanager)                       | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab/-/issues)                                                     |
| Docker Distribution Pruner                                                       | [Issue Tracker](https://gitlab.com/gitlab-org/docker-distribution-pruner)                                          |
| Gitaly                                                                           | [Issue Tracker](https://gitlab.com/gitlab-org/gitaly/-/issues)                                                     |
| GitLab Compose Kit                                                               | [Issuer Tracker](https://gitlab.com/gitlab-org/gitlab-compose-kit/-/issues)                                        |
| GitLab container registry                                                        | [Issue Tracker](https://gitlab.com/gitlab-org/container-registry)                                                  |
| GitLab Elasticsearch Indexer                                                     | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer/-/issues)                               |
| GitLab Zoekt Indexer                                                             | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/issues)                                       |
| GitLab agent server for Kubernetes (KAS)                                         | [Issue Tracker](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues)                           |
| GitLab Pages                                                                     | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab-pages/-/issues)                                               |
| GitLab Shell                                                                     | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab-shell/-/issues)                                               |
| GitLab Workhorse                                                                 | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab/-/issues)                                                     |
| LabKit                                                                           | [Issue Tracker](https://gitlab.com/gitlab-org/labkit/-/issues)                                                     |
| Spamcheck                                                                        | [Issue Tracker](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck) |
| GitLab Workspaces Proxy                                                          | [Issue Tracker](https://gitlab.com/gitlab-org/remote-development/gitlab-workspaces-proxy)                          |
| Devfile Gem                                                                      | [Issue Tracker](https://gitlab.com/gitlab-org/ruby/gems/devfile-gem/-/tree/main/ext?ref_type=heads)                |
| GitLab Operator                                                                  | [Issue Tracker](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator)                                        |
| [Node Exporter](https://github.com/prometheus/node_exporter)                     | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab/-/issues)                                                     |
| [PgBouncer Exporter](https://github.com/prometheus-community/pgbouncer_exporter) | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab/-/issues)                                                     |
| [Postgres Exporter](https://github.com/prometheus-community/postgres_exporter)   | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab/-/issues)                                                     |
| [Prometheus](https://github.com/prometheus/prometheus)                           | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab/-/issues)                                                     |
| [Redis Exporter](https://github.com/oliver006/redis_exporter)                    | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab/-/issues)                                                     |

##### Final updates for release

After all components listed in the tables above build successfully, the directly
responsible individual may then authorize updates to the build images used
to ship GitLab packages and Cloud Native images to customers.

| Component Name                                                                   | Where to track work                                                                                                |
|----------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| GitLab Omnibus Builder                                                           | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab-omnibus-builder)                                             |
| Cloud Native GitLab                                                              | [Issue Tracker](https://gitlab.com/gitlab-org/build/CNG)                                                           |

##### Released independently

Although these components must be updated, they do not block the Go/No-Go
decision for a GitLab release. If they lag behind, the directly responsible
individual should escalate them to Product and Engineering management.

| Component Name                                                                   | Where to track work                                                                                                |
|----------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| GitLab Browser-based DAST                                                        | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab/-/issues)                                                     |
| GitLab Coverage Fuzzer                                                           | [Issue Tracker](https://gitlab.com/gitlab-org/gitlab/-/issues)                                                     |
| GitLab CLI (`glab`).                                                             | [Issue Tracker](https://gitlab.com/gitlab-org/cli/-/issues)                                                        |

#### Communication plan

Communication is required at several key points throughout the process and should
be included in the relevant issues as part of the definition of done:

1. Immediately after creating the epic, it should be posted to Slack. Community members must ask the pinged engineering managers for assistance with this step. The responsible GitLab team member should share a link to the epic in the following Slack channels:
   - `#backend`
   - `#development`
1. Immediately after merging the GitLab Development Kit Update, the same maintainer should add an entry to the engineering week-in-review sync and
   announce the change in the following Slack channels:
   - `#backend`
   - `#development`
1. Immediately upon merge of the updated Go versions in
   [Cloud-Native GitLab](https://gitlab.com/gitlab-org/build/CNG) and
   [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab) add the
   change to the engineering-week-in-review sync and announce in the following
   Slack channels:
   - `#backend`
   - `#development`
   - `#releases`

#### Upgrade validation

Upstream component maintainers must validate their Go-based projects using:

- Established unit tests in the codebase.
- Procedures established in [Merge Request Performance Guidelines](../merge_request_concepts/performance.md).
- Procedures established in [Performance, Reliability, and Availability guidelines](../code_review.md#performance-reliability-and-availability).

Upstream component maintainers should consider validating their Go-based
projects with:

- Isolated component operation performance tests.

  Integration tests are costly and should be testing inter-component
  operational issues. Isolated component testing reduces mean time to
  feedback on updates and decreases resource burn across the organization.

- Components should have end-to-end test coverage in the GitLab Performance Test tool.
- Integration validation through installation of fresh packages **_and_** upgrade from previous versions for:
  - Single GitLab Node
  - Reference Architecture Deployment
  - Geo Deployment
