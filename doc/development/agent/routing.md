---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Routing `kas` requests in the Kubernetes Agent **(PREMIUM SELF)**

This document describes how `kas` routes requests to concrete `agentk` instances.
GitLab must talk to GitLab Kubernetes Agent Server (`kas`) to:

- Get information about connected agents. [Read more](https://gitlab.com/gitlab-org/gitlab/-/issues/249560).
- Interact with agents. [Read more](https://gitlab.com/gitlab-org/gitlab/-/issues/230571).
- Interact with Kubernetes clusters. [Read more](https://gitlab.com/gitlab-org/gitlab/-/issues/240918).

Each agent connects to an instance of `kas` and keeps an open connection. When
GitLab must talk to a particular agent, a `kas` instance connected to this agent must
be found, and the request routed to it.

## System design

For an architecture overview please see
[architecture.md](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md).

```mermaid
flowchart LR
  subgraph "Kubernetes 1"
    agentk1p1["agentk 1, Pod1"]
    agentk1p2["agentk 1, Pod2"]
  end

  subgraph "Kubernetes 2"
    agentk2p1["agentk 2, Pod1"]
  end

  subgraph "Kubernetes 3"
    agentk3p1["agentk 3, Pod1"]
  end

  subgraph kas
    kas1["kas 1"]
    kas2["kas 2"]
    kas3["kas 3"]
  end

  GitLab["GitLab Rails"]
  Redis

  GitLab -- "gRPC to any kas" --> kas
  kas1 -- register connected agents --> Redis
  kas2 -- register connected agents --> Redis
  kas1 -- lookup agent --> Redis

  agentk1p1 -- "gRPC" --> kas1
  agentk1p2 -- "gRPC" --> kas2
  agentk2p1 -- "gRPC" --> kas1
  agentk3p1 -- "gRPC" --> kas2
```

For this architecture, this diagram shows a request to `agentk 3, Pod1` for the list of pods:

```mermaid
sequenceDiagram
  GitLab->>+kas1: Get list of running<br />Pods from agentk<br />with agent_id=3
  Note right of kas1: kas1 checks for<br />agent connected with agent_id=3.<br />It does not.<br />Queries Redis
  kas1->>+Redis: Get list of connected agents<br />with agent_id=3
  Redis-->-kas1: List of connected agents<br />with agent_id=3
  Note right of kas1: kas1 picks a specific agentk instance<br />to address and talks to<br />the corresponding kas instance,<br />specifying which agentk instance<br />to route the request to.
  kas1->>+kas2: Get the list of running Pods<br />from agentk 3, Pod1
  kas2->>+agentk 3 Pod1: Get list of Pods
  agentk 3 Pod1->>-kas2: Get list of Pods
  kas2-->>-kas1: List of running Pods<br />from agentk 3, Pod1
  kas1-->>-GitLab: List of running Pods<br />from agentk with agent_id=3
```

Each `kas` instance tracks the agents connected to it in Redis. For each agent, it
stores a serialized protobuf object with information about the agent. When an agent
disconnects, `kas` removes all corresponding information from Redis. For both events,
`kas` publishes a notification to a Redis [pub-sub channel](https://redis.io/topics/pubsub).

Each agent, while logically a single entity, can have multiple replicas (multiple pods)
in a cluster. `kas` accommodates that and records per-replica (generally per-connection)
information. Each open `GetConfiguration()` streaming request is given
a unique identifier which, combined with agent ID, identifies an `agentk` instance.

gRPC can keep multiple TCP connections open for a single target host. `agentk` only
runs one `GetConfiguration()` streaming request. `kas` uses that connection, and
doesn't see idle TCP connections because they are handled by the gRPC framework.

Each `kas` instance provides information to Redis, so other `kas` instances can discover and access it.

Information is stored in Redis with an [expiration time](https://redis.io/commands/expire),
to expire information for `kas` instances that become unavailable. To prevent
information from expiring too quickly, `kas` periodically updates the expiration time
for valid entries. Before terminating, `kas` cleans up the information it adds into Redis.

When `kas` must atomically update multiple data structures in Redis, it uses
[transactions](https://redis.io/topics/transactions) to ensure data consistency.
Grouped data items must have the same expiration time.

In addition to the existing `agentk -> kas` gRPC endpoint, `kas` exposes two new,
separate gRPC endpoints for GitLab and for `kas -> kas` requests. Each endpoint
is a separate network listener, making it easier to control network access to endpoints
and allowing separate configuration for each endpoint.

Databases, like PostgreSQL, aren't used because the data is transient, with no need
to reliably persist it.

### `GitLab : kas` external endpoint

GitLab authenticates with `kas` using JWT and the same shared secret used by the
`kas -> GitLab` communication. The JWT issuer should be `gitlab` and the audience
should be `gitlab-kas`.

When accessed through this endpoint, `kas` plays the role of request router.

If a request from GitLab comes but no connected agent can handle it, `kas` blocks
and waits for a suitable agent to connect to it or to another `kas` instance. It
stops waiting when the client disconnects, or when some long timeout happens, such
as client timeout. `kas` is notified of new agent connections through a
[pub-sub channel](https://redis.io/topics/pubsub) to avoid frequent polling.
When a suitable agent connects, `kas` routes the request to it.

### `kas : kas` internal endpoint

This endpoint is an implementation detail, an internal API, and should not be used
by any other system. It's protected by JWT using a secret, shared among all `kas`
instances. No other system must have access to this secret.

When accessed through this endpoint, `kas` uses the request itself to determine
which `agentk` to send the request to. It prevents request cycles by only following
the instructions in the request, rather than doing discovery. It's the responsibility
of the `kas` receiving the request from the _external_ endpoint to retry and re-route
requests. This method ensures a single central component for each request can determine
how a request is routed, rather than distributing the decision across several `kas` instances.

### Reverse gRPC tunnel

This section explains how the `agentk` -> `kas` reverse gRPC tunnel is implemented.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video overview of how some of the blocks map to code, see
[GitLab Kubernetes Agent reverse gRPC tunnel architecture and code overview
](https://www.youtube.com/watch?v=9pnQF76hyZc).

#### High level schema

In this example, `Server side of module A` exposes its API to get the `Pod` list
on the `Public API gRPC server`. When it receives a request, it must determine
the agent ID from it, then call the proxying code which forwards the request to
a suitable `agentk` that can handle it.

The `Agent side of module A` exposes the same API on the `Internal gRPC server`.
When it receives the request, it needs to handle it (such as retrieving and returning
the `Pod` list).

This schema describes how reverse tunneling is handled fully transparently
for modules, so you can add new features:

```mermaid
graph TB
    subgraph kas
        server-internal-grpc-server[Internal gRPC server]
        server-api-grpc-server[Public API gRPC server]
        server-module-a[Server side of module A]
        server-module-b[Server side of module B]
    end
    subgraph agentk
        agent-internal-grpc-server[Internal gRPC server]
        agent-module-a[Agent side of module A]
        agent-module-b[Agent side of module B]
    end

    agent-internal-grpc-server -- request --> agent-module-a
    agent-internal-grpc-server -- request --> agent-module-b

    server-module-a-. expose API on .-> server-internal-grpc-server
    server-module-b-. expose API on .-> server-api-grpc-server

    server-internal-grpc-server -- proxy request --> agent-internal-grpc-server
    server-api-grpc-server -- proxy request --> agent-internal-grpc-server
```

#### Implementation schema

`HandleTunnelConnection()` is called with the server-side interface of the reverse
tunnel. It registers the connection and blocks, waiting for a request to proxy
through the connection.

`HandleIncomingConnection()` is called with the server-side interface of the incoming
connection. It registers the connection and blocks, waiting for a matching tunnel
to proxy the connection through.

After it has two connections that match, `Connection registry` starts bi-directional
data streaming:

```mermaid
graph TB
    subgraph kas
        server-tunnel-module[Server tunnel module]
        connection-registry[Connection registry]
        server-internal-grpc-server[Internal gRPC server]
        server-api-grpc-server[Public API gRPC server]
        server-module-a[Server side of module A]
        server-module-b[Server side of module B]
    end
    subgraph agentk
        agent-internal-grpc-server[Internal gRPC server]
        agent-tunnel-module[Agent tunnel module]
        agent-module-a[Agent side of module A]
        agent-module-b[Agent side of module B]
    end

    server-tunnel-module -- "HandleTunnelConnection()" --> connection-registry
    server-internal-grpc-server -- "HandleIncomingConnection()" --> connection-registry
    server-api-grpc-server -- "HandleIncomingConnection()" --> connection-registry
    server-module-a-. expose API on .-> server-internal-grpc-server
    server-module-b-. expose API on .-> server-api-grpc-server

    agent-tunnel-module -- "establish tunnel, receive request" --> server-tunnel-module
    agent-tunnel-module -- make request --> agent-internal-grpc-server
    agent-internal-grpc-server -- request --> agent-module-a
    agent-internal-grpc-server -- request --> agent-module-b
```

### API definitions

- [`agent_tracker/agent_tracker.proto`](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/agent_tracker/agent_tracker.proto)
- [`agent_tracker/rpc/rpc.proto`](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/agent_tracker/rpc/rpc.proto)
- [`reverse_tunnel/rpc/rpc.proto`](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/reverse_tunnel/rpc/rpc.proto)
