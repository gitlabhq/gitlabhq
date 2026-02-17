---
stage: Verify
group: Runner Core
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'Tutorial: Build a runner admission controller'
---

<!-- vale gitlab_base.FutureTense = NO -->

This tutorial guides you through building a runner admission controller that enforces
custom policies for CI/CD job execution. You'll create a controller in Go that connects
to the job router and implements an image allowlist policy.

The code examples in this tutorial are adapted from the
[runner-controller-example](https://gitlab.com/gitlab-org/cluster-integration/runner-controller-example)
repository, which provides a complete reference implementation you can use as a starting point.

By the end of this tutorial, you'll have a working admission controller that:

- Connects to the job router using gRPC
- Registers itself with GitLab
- Receives job admission requests
- Evaluates jobs against a custom policy
- Returns admission decisions

To build a runner admission controller:

1. [Create a runner controller in GitLab](#create-a-runner-controller-in-gitlab)
1. [Scope the runner controller](#scope-the-runner-controller)
1. [Create a runner controller token](#create-a-runner-controller-token)
1. [Set up your Go project](#set-up-your-go-project)
1. [Generate client code from protobuf definitions](#generate-client-code-from-protobuf-definitions)
1. [Implement authentication](#implement-authentication)
1. [Implement agent registration](#implement-agent-registration)
1. [Implement the admission loop](#implement-the-admission-loop)
1. [Implement an admission policy](#implement-an-admission-policy)
1. [Test with dry run state](#test-with-dry-run-state)
1. [Enable in production](#enable-in-production)

## Before you begin

Make sure you have:

- GitLab Self-Managed or GitLab Dedicated with Ultimate tier
- Administrator access to your GitLab instance
- One of the following to interact with the GitLab API:
  - [GitLab CLI (`glab`)](https://docs.gitlab.com/cli/) 1.85.0 or later, authenticated with `glab auth login`
  - `curl` or another HTTP client
- Go 1.21 or later installed
- [The `buf` CLI](https://buf.build/docs/installation) installed for generating Protobuf code
- The following feature flags enabled on your GitLab instance:
  - `job_router`
  - `job_router_admission_control`
- GitLab Runner 18.9 or later with `FF_USE_JOB_ROUTER` environment variable set to `true`.

## Create a runner controller in GitLab

Use the [runner controllers API](../../api/runner_controllers.md) to create a runner controller.

Start with `dry_run` state to validate your controller behavior before enabling enforcement:

{{< tabs >}}

{{< tab title="GitLab CLI" >}}

```shell
glab runner-controller create --description "Image allowlist controller" --state dry_run
```

{{< /tab >}}

{{< tab title="curl" >}}

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "Image allowlist controller", "state": "dry_run"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers"
```

{{< /tab >}}

{{< /tabs >}}

Save the returned `id` for the next step.

## Scope the runner controller

Runner controllers must be scoped to receive admission requests. Without a scope,
your controller remains inactive even when enabled.

For this tutorial, scope the controller to all runners in the instance:

{{< tabs >}}

{{< tab title="GitLab CLI" >}}

```shell
glab runner-controller scope create <controller_id> --instance
```

{{< /tab >}}

{{< tab title="curl" >}}

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/<controller_id>/scopes/instance"
```

{{< /tab >}}

{{< /tabs >}}

Alternatively, you can scope the controller to specific runners using the
[Runner controllers API](../../api/runner_controllers.md). Use runner-level scoping
when you want the controller to evaluate jobs only for certain runners.

## Create a runner controller token

Create a token for your runner controller to authenticate with the job router:

{{< tabs >}}

{{< tab title="GitLab CLI" >}}

```shell
glab runner-controller token create <controller_id> --description "Production token"
```

{{< /tab >}}

{{< tab title="curl" >}}

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "Production token"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers/<controller_id>/tokens"
```

{{< /tab >}}

{{< /tabs >}}

Save the returned `token` value securely. The token is only displayed once.

## Set up your Go project

Create a new Go project:

```shell
mkdir runner-admission-controller
cd runner-admission-controller
go mod init example.com/runner-admission-controller
```

## Generate client code from protobuf definitions

You need to generate gRPC client code from the Protobuf definitions in the
[GitLab Agent for Kubernetes](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent) repository.
You can use any method you prefer, including:

- Vendoring the `.proto` files manually and using `protoc` directly.
- Using [`buf`](https://buf.build/) to fetch and generate code automatically.

For details on the Protobuf definitions, see
[generating client code](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md#generating-client-code)
in the runner controller specification.

This tutorial uses `buf`. Create `buf.gen.yaml`:

```yaml
version: v2

managed:
  enabled: true

  disable:
    - module: buf.build/bufbuild/protovalidate

  override:
    - file_option: go_package
      value: internal/rpc

inputs:
  - git_repo: https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent.git
    branch: master

plugins:
  - local: ["go", "run", "google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.10"]
    out: .
  - local: ["go", "run", "google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1"]
    out: .
```

Generate the code:

```shell
buf generate
```

This creates the gRPC client code in `internal/rpc/`.

## Implement authentication

Runner controllers authenticate with the job router using gRPC metadata headers.
For specification details, see
[Authentication](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md#authentication)
in the runner controller specification.

Create a credentials provider that includes the required headers:

```go
type tokenCredentials struct {
    token string
}

func (t *tokenCredentials) GetRequestMetadata(ctx context.Context, uri ...string) (map[string]string, error) {
    return map[string]string{
        "authorization":     "Bearer " + t.token,
        "gitlab-agent-type": "runnerc",
    }, nil
}

func (t *tokenCredentials) RequireTransportSecurity() bool {
    return true
}
```

Use the following code to create the gRPC connection:

```go
conn, err := grpc.NewClient(kasAddress,
    grpc.WithTransportCredentials(credentials.NewTLS(nil)),
    grpc.WithPerRPCCredentials(&tokenCredentials{token: agentToken}),
)
```

## Implement agent registration

Register your controller with the job router for presence tracking and monitoring.
Re-register periodically (recommended: every 3 minutes) to maintain presence.
For specification details, see
[AgentRegistrar](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md#agentregistrar)
in the runner controller specification.

```go
func registerAgent(ctx context.Context, conn *grpc.ClientConn, instanceID int64) error {
    client := rpc.NewAgentRegistrarClient(conn)

    _, err := client.Register(ctx, &rpc.RegisterRequest{
        Meta: &rpc.Meta{
            Version:      "1.0.0",
            GitRef:       "main",
            Architecture: runtime.GOARCH,
        },
        InstanceId: instanceID,
    })
    return err
}
```

## Implement the admission loop

The admission loop receives job details from the job router and sends decisions.
For specification details, see
[RunnerControllerService](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md#runnercontrollerservice)
and [Protocol Flow](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md#protocol-flow)
in the runner controller specification.

```go
func handleAdmissionRequest(ctx context.Context, client rpc.RunnerControllerServiceClient) error {
    admissionCtx, cancel := context.WithCancel(ctx)
    defer cancel()

    stream, err := client.AdmitJob(admissionCtx)
    if err != nil {
        return err
    }

    // Wait for admission request
    req, err := stream.Recv()
    if err != nil {
        return err
    }

    // Evaluate the job (implement your policy here)
    admitted, reason := evaluateJob(req)

    // Send decision
    var resp *rpc.AdmitJobResponse
    if admitted {
        resp = &rpc.AdmitJobResponse{
            AdmissionResponse: &rpc.AdmitJobResponse_Admitted{Admitted: &rpc.Admitted{}},
        }
    } else {
        resp = &rpc.AdmitJobResponse{
            AdmissionResponse: &rpc.AdmitJobResponse_Rejected{
                Rejected: &rpc.Rejected{Reason: reason},
            },
        }
    }

    if err := stream.Send(resp); err != nil {
        return err
    }

    _ = stream.CloseSend()
    var x any
    err = stream.RecvMsg(x) // consume EOF
    if err != io.EOF {
      return err
    }

    return nil
}
```

## Implement an admission policy

Implement your custom policy logic. This example rejects images with the `:latest` tag:

```go
func evaluateJob(req *rpc.AdmitJobRequest) (admitted bool, reason string) {
    imageName := req.GetImage().GetName()

    // Reject :latest tags
    if strings.HasSuffix(imageName, ":latest") {
        return false, "images with :latest tag are not allowed"
    }

    // Check allowlist
    allowed := []string{"alpine", "ubuntu", "golang", "ruby", "node", "python"}
    for _, prefix := range allowed {
        if strings.HasPrefix(imageName, prefix) {
            return true, ""
        }
    }

    return false, fmt.Sprintf("image %s is not in the approved list", imageName)
}
```

## Test with dry run state

With your controller running and in `dry_run` state, trigger a CI/CD pipeline.
Check your controller logs to verify it receives admission requests.
The job router logs decisions but does not enforce them for controllers in dry run state.
This action allows you to validate behavior and de-risk your deployment before you enable enforcement.

## Enable in production

After validating your controller behavior in `dry_run` state, update to `enabled` state:

{{< tabs >}}

{{< tab title="GitLab CLI" >}}

```shell
glab runner-controller update <controller_id> --state enabled
```

{{< /tab >}}

{{< tab title="curl" >}}

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"state": "enabled"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers/<controller_id>"
```

{{< /tab >}}

{{< /tabs >}}

Now your admission decisions affect job execution.

### Hosting the runner controller

The runner controller hosting is up to you depending on the scale of the GitLab instance
and the load of jobs that are affected by admission control.
The only requirement is that the GitLab instance is reachable by the runner controller,
because that is where it connects to.

## Next steps

- Review the [complete example implementation](https://gitlab.com/gitlab-org/cluster-integration/runner-controller-example).
- Read the [runner controller specification](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md) for protocol details.
- Explore using [Open Policy Agent (OPA)](https://www.openpolicyagent.org/) for more complex policies.
