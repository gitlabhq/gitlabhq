---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
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

Individual Go projects might need to support multiple Go versions because:

- When a new version of Go is released, we should start integrating it into the CI pipelines to verify forward compatibility.
- To enable backports, we must support the versions of Go [shipped by Distribution](#testing-against-shipped-go-versions) in the latest 3 minor GitLab releases, excluding the active milestone.

## Updating Go version

We should always:

- Use the same Go version for Omnibus GitLab and Cloud Native GitLab.
- Use a [supported version](https://go.dev/doc/devel/release#policy).
- Use the most recent patch-level for that version to keep up with security fixes.

Changing the version affects every project being compiled, so it's important to
ensure that all projects have been updated to test against the new Go version
before changing the package builders to use it. Despite [Go's compatibility promise](https://go.dev/doc/go1compat),
changes between minor versions can expose bugs or cause problems in our projects.

### Version in `go.mod`

**Key Requirements:**

- Always use `0` as the patch version (for example, `go 1.23.0`, not `go 1.23.4`).
- Do not set a version newer than what is used in CNG and Omnibus, otherwise this will cause build failures.
- Do not use the `toolchain` directive in `go.mod` files, as it has been causing issues when building the project with different Go versions.

The Go version in your `go.mod` affects all downstream projects.
When you specify a minimum Go version, any project that imports your package must use that version or newer.
This can create impossible situations for projects with different Go version constraints.

For example, if CNG uses Go 1.23.4 but your project declares `go 1.23.5` as the minimum required version, CNG will
fail to build your package.
Similarly, other projects importing your package will be forced to upgrade their Go version, which may not be feasible.

[See above](#testing-against-shipped-go-versions) to find out what versions are used in CNG and Omnibus.

From the [Go Modules Reference](https://go.dev/ref/mod#go-mod-file-go):

> The go directive sets the minimum version of Go required to use this module.

You don't need to set `go 1.24.0` to be compatible with Go 1.24.0.
Having it at `go 1.23.0` works fine.
Go 1.23.0 and any newer version will almost certainly build your package without issues thanks to the
[Go 1 compatibility promise](https://go.dev/doc/go1compat).

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

1. Navigate to the [Build Architecture Configuration pipelines page](https://gitlab.com/gitlab-org/distribution/build-architecture/framework/configuration/-/pipelines).
1. Create a new pipeline for a dry run with these variables:
   - Set `COMPONENT_UPGRADE` to `true`.
   - Set `COMPONENT_NAME` to `golang.`
   - Set `COMPONENT_VERSION` to the target upgrade version.
1. Run the pipeline.
1. Check for errors in the dry run pipeline. If any subscriber files throw errors because labels changed or directly responsible individuals are no
   longer valid, contact the subscriber project and request they update their configuration.
1. After a successful dry-run pipeline, create another pipeline with these variables to create the upgrade epic and all associated issues:
   - Set `COMPONENT_UPGRADE` to `true`.
   - Set `COMPONENT_NAME` to `golang.`
   - Set `COMPONENT_VERSION` to the target upgrade version.
   - Set `EPIC_DRY_RUN` to `false`.
1. Run the pipeline.

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
