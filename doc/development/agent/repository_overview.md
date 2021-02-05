---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Kubernetes Agent repository overview **(PREMIUM SELF)**

This page describes the subfolders of the Kubernetes Agent repository.
[Development information](index.md) and
[end-user documentation](../../user/clusters/agent/index.md) are both available.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video overview, see
[GitLab Kubernetes Agent repository overview](https://www.youtube.com/watch?v=j8CyaCWroUY).

## `build`

Various files for the build process.

### `build/deployment`

A [`kpt`](https://googlecontainertools.github.io/kpt/) package that bundles some
[Kustomize](https://kustomize.io/) layers and components. Can be used as-is, or
to create a custom package to install `agentk`.

## `cmd`

Commands are binaries that this repository produces. They are:

- `kas` is the GitLab Kubernetes Agent Server binary.
- `agentk` is the GitLab Kubernetes Agent binary.

Each of these directories contain application bootstrap code for:

- Reading configuration.
- Applying defaults to it.
- Constructing the dependency graph of objects that constitute the program.
- Running it.

### `cmd/agentk`

- `agentk` initialization logic.
- Implementation of the agent modules API.

### `cmd/kas`

- `kas` initialization logic.
- Implementation of the server modules API.

## `examples`

Git submodules for the example projects.

## `internal`

The main code of both `gitlab-kas` and `agentk`, and various supporting building blocks.

### `internal/api`

Structs that represent some important pieces of data.

### `internal/gitaly`

Items to work with [Gitaly](../../administration/gitaly/index.md).

### `internal/gitlab`

GitLab REST client.

### `internal/module`

Modules that implement server and agent-side functionality.

### `internal/tool`

Various building blocks. `internal/tool/testing` contains mocks and helpers
for testing. Mocks are generated with [`gomock`](https://pkg.go.dev/github.com/golang/mock).

## `it`

Contains scaffolding for integration tests. Unused at the moment.

## `pkg`

Contains exported packages.

### `pkg/agentcfg`

Contains protobuf definitions of the `agentk` configuration file. Used to configure
the agent through a configuration repository.

### `pkg/kascfg`

Contains protobuf definitions of the `gitlab-kas` configuration file. Contains an
example of that configuration file along with the test for it. The test ensures
the configuration file example is in sync with the protobuf definitions of the
file and defaults, which are applied when the file is loaded.
