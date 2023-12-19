---
owning-stage: "~devops::verify"
description: Runner integration for [CI Steps](index.md).
---

# Runner Integration

Steps are delivered to Step Runner as a YAML blob in the GitLab CI syntax.
Runner interacts with Step Runner over a gRPC service `StepRunner`
which is started on a local socket in the execution environment. This
is the same way that Nesting serves a gRPC service in a dedicated
Mac instance. The service has three RPCs, `run`, `follow` and `cancel`.

Run is the initial delivery of the steps. Follow requests a streaming
response to step traces. And Cancel stops execution and cleans up
resources as soon as possible.

Step Runner operating in gRPC mode will be able to executed multiple
step payloads at once. That is each call to `run` will start a new
goroutine and execute the steps until completion. Multiple calls to `run`
may be made simultaneously. This is also why components are cached by
`location`, `version` and `hash`. Because we cannot be changing which
ref we are on while multiple, concurrent executions are using the
underlying files.

```proto
service StepRunner {
    rpc Run(RunRequest) returns (RunResponse);
    rpc Follow(FollowRequest) returns (stream FollowResponse);
    rpc Cancel(CancelRequest) returns (CancelResponse);
}

message RunRequest {
    string id = 1;
    oneof job_oneof {
        string ci_job = 2;
        Steps steps = 3;
    }
}

message RunResponse {
}

message FollowRequest {
    string id = 1;
}

message FollowResponse {
    StepResult result = 1;
}

message CancelRequest {
    string id = 1;
}

message CancelResponse {
}
```

As steps are executed, traces are streamed back to GitLab Runner.
So execution can be followed at least at the step level. If a more
granular follow is required, we can introduce a gRPC step type which
can stream back logs as they are produced.

Here is how we will connect to Step Runner in each runner executor:

## Instance

The Instance executor is accessed via SSH, the same as today. However
instead of starting a bash shell and piping in commands, it connects
to the Step Runner socket in a known location and makes gRPC
calls. This is the same as how Runner calls the Nesting server in
dedicated Mac instances to make VMs.

This requires that Step Runner is present and started in the job
execution environment.

## Docker

The same requirement that Step Runner is present and started is true
for the Docker executor (and `docker-autoscaler`). However in order to
connect to the socket inside the container, we must `exec` a bridge
process in the container. This will be another command on the Step
Runner binary which proxies STDIN and STDOUT to the local socket in a
known location, allowing the caller of exec to make gRPC calls inside
the container.

## Kubernetes

The Kubelet on Kubernetes Nodes exposes an exec API which will start a
process in a container of a running Pod. We will use this exec create
a bridge process that will allow the caller to make gRPC calls inside
the Pod. Same as the Docker executor.

In order to access to this protected Kubelet API we must use the
Kubernetes API which provides an exec sub-resource on Pod. A caller
can POST to the URL of a pod suffixed with `/exec` and then negotiate
the connection up to a SPDY protocol for bidirectional byte
streaming. So GitLab Runner can use the Kubernetes API to connect to
the Step Runner service and deliver job payloads.

This is the same way that `kubectl exec` works. In fact most of the
internals such as SPDY negotiation are provided as `client-go`
libraries. So Runner can call the Kubernetes API directly by
importing the necessary libraries rather than shelling out to
Kubectl.

Historically one of the weaknesses of the Kubernetes Executor was
running a whole job through a single exec. To mitigate this Runner
uses the attach command instead, which can "re-attach" to an existing
shell process and pick up where it left off.

This is not necessary for Step Runner however, because the exec is
just establishing a bridge to the long-running gRPC process. If the
connection drops, Runner will just "re-attach" by exec'ing another
connection and continuing to make RPC calls like `follow`.
