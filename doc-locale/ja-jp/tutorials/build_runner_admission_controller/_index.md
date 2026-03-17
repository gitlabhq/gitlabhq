---
stage: Verify
group: Runner Core
info: For assistance with this tutorial, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects>.
title: 'チュートリアル: Runnerコントローラーの許可リストをビルドする'
---

<!-- vale gitlab_base.FutureTense = NO -->

このチュートリアルでは、CI/CDジョブの実行に関するカスタムポリシーを適用する、Runnerコントローラーのビルドについて説明します。Goでコントローラーを作成し、ジョブルーターに接続して、イメージ許可リストポリシーを実装します。

このチュートリアルのコード例は、[runner-controller-example](https://gitlab.com/gitlab-org/cluster-integration/runner-controller-example)リポジトリから転載したもので、出発点として使用できる完全な参照実装を提供します。

このチュートリアルを終えるまでに、次のことを行う、実用的なコントローラーが完成します:

- gRPCを使用してジョブルーターに接続する
- GitLabに自身を登録する
- ジョブアドミッションリクエストを受信する
- カスタムポリシーに対してジョブを検証する
- アドミッションの決定を返す

Runnerコントローラーをビルドするには、次の手順を実行します:

1. [GitLabでRunnerコントローラーを作成する](#create-a-runner-controller-in-gitlab)
1. [Runnerコントローラーのスコープを設定する](#scope-the-runner-controller)
1. [Runnerコントローラートークンを作成する](#create-a-runner-controller-token)
1. [Goプロジェクトをセットアップする](#set-up-your-go-project)
1. [protobuf定義からクライアントコードを生成する](#generate-client-code-from-protobuf-definitions)
1. [認証を実装する](#implement-authentication)
1. [エージェント登録を実装する](#implement-agent-registration)
1. [アドミッションループを実装する](#implement-the-admission-loop)
1. [アドミッションポリシーを実装する](#implement-an-admission-policy)
1. [ドライラン状態でテストする](#test-with-dry-run-state)
1. [本番環境で有効にする](#enable-in-production)

## はじめる前 {#before-you-begin}

以下を確認してください:

- UltimateティアのGitLabセルフマネージドまたはGitLab Dedicated
- GitLabインスタンスへの管理者アクセス
- GitLab APIとやり取りするための次のいずれか:
  - [GitLab CLI (`glab`)](https://docs.gitlab.com/cli/) 1.85.0以降。`glab auth login`で認証されています
  - `curl`または別のHTTPクライアント
- Go 1.21以降がインストールされている
- [Protobufコードを生成するためにインストールされた`buf` CLI](https://buf.build/docs/installation)
- GitLabインスタンスで次の機能フラグが有効になっている:
  - `job_router`
  - `job_router_admission_control`
- `FF_USE_JOB_ROUTER`環境変数が`true`に設定されたGitLab Runner 18.9以降。

## GitLabでRunnerコントローラーを作成する {#create-a-runner-controller-in-gitlab}

[RunnerコントローラーAPI](../../api/runner_controllers.md)を使用して、Runnerコントローラーを作成します。

`dry_run`状態から開始して、適用を有効にする前に、コントローラーの動作を検証します:

{{< tabs >}}

{{< tab title="GitLab CLI" >}}

```shell
glab runner-controller create --description "Image allowlist controller" --state dry_run
```

{{< /tab >}}

{{< tab title="cURL" >}}

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "Image allowlist controller", "state": "dry_run"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers"
```

{{< /tab >}}

{{< /tabs >}}

次の手順のために、返された`id`を保存します。

## Runnerコントローラーのスコープを設定する {#scope-the-runner-controller}

Runnerコントローラーは、アドミッションリクエストを受信するようにスコープを設定する必要があります。スコープがないと、有効にしてもコントローラーは非アクティブのままになります。

このチュートリアルでは、インスタンス内のすべてのRunnerにコントローラーのスコープを設定します:

{{< tabs >}}

{{< tab title="GitLab CLI" >}}

```shell
glab runner-controller scope create <controller_id> --instance
```

{{< /tab >}}

{{< tab title="cURL" >}}

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/<controller_id>/scopes/instance"
```

{{< /tab >}}

{{< /tabs >}}

または、[RunnerコントローラーAPI](../../api/runner_controllers.md)を使用して、特定のRunnerにコントローラーのスコープを設定することもできます。特定のRunnerに対してのみジョブを検証するようにコントローラーを設定する場合は、Runnerレベルのスコープ設定を使用します。

## Runnerコントローラートークンを作成する {#create-a-runner-controller-token}

ジョブルーターで認証するために、Runnerコントローラーのトークンを作成します:

{{< tabs >}}

{{< tab title="GitLab CLI" >}}

```shell
glab runner-controller token create <controller_id> --description "Production token"
```

{{< /tab >}}

{{< tab title="cURL" >}}

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "Production token"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers/<controller_id>/tokens"
```

{{< /tab >}}

{{< /tabs >}}

返された`token`値を安全に保存します。トークンは一度しか表示されません。

## Goプロジェクトをセットアップする {#set-up-your-go-project}

新しいGoプロジェクトを作成します:

```shell
mkdir runner-admission-controller
cd runner-admission-controller
go mod init example.com/runner-admission-controller
```

## protobuf定義からクライアントコードを生成する {#generate-client-code-from-protobuf-definitions}

[Kubernetes向けGitLabエージェント](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent)リポジトリ内のProtobuf定義からgRPCクライアントコードを生成する必要があります。次の方法を含め、任意の方法を使用できます:

- `.proto`ファイルをフェッチして、`protoc`を直接使用します。
- [`buf`を使用](https://buf.build/)してコードを自動的にフェッチおよび生成します。

Protobuf定義の詳細については、Runnerコントローラーの仕様の[クライアントコードの生成](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md#generating-client-code)を参照してください。

このチュートリアルでは、`buf`を使用します。`buf.gen.yaml`を作成します:

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

コードを生成します:

```shell
buf generate
```

これにより、gRPCクライアントコードが`internal/rpc/`に作成されます。

## 認証を実装する {#implement-authentication}

Runnerコントローラーは、gRPCメタデータヘッダーを使用してジョブルーターで認証します。仕様の詳細については、Runnerコントローラーの仕様の[認証](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md#authentication)を参照してください。

必要なヘッダーを含む認証情報プロバイダーを作成します:

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

次のコードを使用して、gRPC接続を作成します:

```go
conn, err := grpc.NewClient(kasAddress,
    grpc.WithTransportCredentials(credentials.NewTLS(nil)),
    grpc.WithPerRPCCredentials(&tokenCredentials{token: agentToken}),
)
```

## エージェント登録を実装する {#implement-agent-registration}

プレゼンストラッキングとモニタリングのために、ジョブルーターにコントローラーを登録します。プレゼンスを維持するために、定期的に再登録します（推奨：3分ごと）。仕様の詳細については、Runnerコントローラーの仕様の[AgentRegistrar](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md#agentregistrar)を参照してください。

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

## アドミッションループを実装する {#implement-the-admission-loop}

アドミッションループは、ジョブルーターからジョブの詳細を受信し、決定を送信します。仕様の詳細については、Runnerコントローラーの仕様の[RunnerControllerService](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md#runnercontrollerservice)と[プロトコルフロー](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md#protocol-flow)を参照してください。

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

## アドミッションポリシーを実装する {#implement-an-admission-policy}

カスタムポリシーロジックを実装します。この例では、`:latest`タグを持つイメージを拒否します:

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

## ドライラン状態でテストする {#test-with-dry-run-state}

コントローラーの実行中、`dry_run`状態の場合、CI/CDパイプラインをトリガーします。コントローラーのログをチェックして、アドミッションリクエストを受信したことを確認します。ジョブルーターは決定をログに記録しますが、ドライラン状態のコントローラーには適用しません。このアクションにより、適用を有効にする前に、動作を検証し、デプロイのリスクを軽減できます。

## 本番環境で有効にする {#enable-in-production}

`dry_run`状態でコントローラーの動作を検証した後、`enabled`状態に更新します:

{{< tabs >}}

{{< tab title="GitLab CLI" >}}

```shell
glab runner-controller update <controller_id> --state enabled
```

{{< /tab >}}

{{< tab title="cURL" >}}

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"state": "enabled"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers/<controller_id>"
```

{{< /tab >}}

{{< /tabs >}}

これで、アドミッションの決定がジョブの実行に影響を与えるようになりました。

### Runnerコントローラーのホスト {#hosting-the-runner-controller}

Runnerコントローラーのホストは、アドミッション制御の影響を受けるジョブのスケールと負荷に応じて異なりますGitLabインスタンスの。唯一の要件は、GitLabインスタンスがRunnerコントローラーから到達可能であることです。それは接続先であるためです。

## 次の手順 {#next-steps}

- [完全な例の実装](https://gitlab.com/gitlab-org/cluster-integration/runner-controller-example)をレビューします。
- プロトコルの詳細については、[Runnerコントローラー仕様](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/runner_controller.md)をお読みください。
- より複雑なポリシーについては、[Open Policy Agent (OPA)](https://www.openpolicyagent.org/)の使用を検討してください。
