---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: フロー実行変数
---

すべての変数が、フローを実行するジョブで使用できるわけではありません。

- 一部の定義済み変数とエージェントプラットフォーム固有の変数が利用可能です。
- 定義済みでフィルターされた変数、カスタムCI/CD変数、およびユーザーID変数は利用できません。

## 利用可能な変数 {#available-variables}

フローを実行するジョブで使用できる変数を以下に示します。

### 定義済み変数 {#predefined-variables}

以下の定義済みCI/CD変数を使用できます:

| 変数 | 説明 |
|----------|-------------|
| `CI_PROJECT_ID` | プロジェクトID。 |
| `CI_PROJECT_NAME` | プロジェクト名。 |
| `CI_PROJECT_PATH` | 名前空間付きのプロジェクトパス。 |
| `CI_PROJECT_URL` | プロジェクトHTTP URL。 |
| `CI_PROJECT_NAMESPACE` | プロジェクト名前空間。 |
| `CI_PROJECT_VISIBILITY` | プロジェクトの表示レベル（`public`、`internal`、または`private`）。 |
| `CI_DEFAULT_BRANCH` | デフォルトのブランチ名。 |
| `CI_JOB_ID` | ジョブID。 |
| `CI_JOB_URL` | ジョブURL。 |
| `CI_JOB_TOKEN` | ジョブ認証トークン。 |
| `CI_JOB_IMAGE` | ジョブに使用されるDockerイメージ。 |
| `CI_JOB_STATUS` | ジョブのステータス。 |
| `CI_JOB_TIMEOUT` | ジョブのタイムアウト（秒単位）。 |
| `CI_JOB_STARTED_AT` | ジョブ開始タイムスタンプ（ISO 8601形式）。 |
| `CI_PIPELINE_ID` | パイプラインID。 |
| `CI_PIPELINE_URL` | パイプラインURL。 |
| `CI_REGISTRY_USER` | コンテナレジストリのユーザー名（`gitlab-ci-token`）。 |
| `CI_REGISTRY_PASSWORD` | コンテナレジストリのパスワード（ジョブトークン）。 |
| `CI_DEPENDENCY_PROXY_USER` | 依存プロキシのユーザー名。 |
| `CI_DEPENDENCY_PROXY_PASSWORD` | 依存プロキシのパスワード。 |
| `CI_REPOSITORY_URL` | 認証情報が埋め込まれたGitクローンURL。 |
| `CI_RUNNER_VERSION` | Runnerバージョン。 |
| `CI_RUNNER_EXECUTABLE_ARCH` | Runnerアーキテクチャ（例：`linux/amd64`）。 |
| `CI_SERVER` | CI/CD環境では常に`yes`。 |
| `CI_WORKLOAD_REF` | フロー実行のワークロード参照（例：`refs/workloads/c727f70ba7f`）。これはGitのブランチではなく、Gitの操作には使用できません。 |

### 環境変数 {#environment-variables}

以下の環境変数は、エージェントプラットフォームに固有のものです。これらの変数は、`setup_script`とメインエージェントランタイムの両方で使用できます。

この表は、主要な変数をまとめたものです。追加の内部変数（たとえば、デバッグフラグとテレメトリ識別子）も実行コンテナに存在する可能性がありますが、フロー設定での使用は意図されていません。

| 変数 | 説明 | 例 |
|----------|-------------|---------|
| `DUO_WORKFLOW_GIT_HTTP_BASE_URL` | GitLabインスタンスのベースURL。`CI_SERVER_URL`の代わりに使用します。 | `https://gitlab.com` |
| `DUO_WORKFLOW_PROJECT_ID` | プロジェクトID:`CI_PROJECT_ID`と同じ値。 | `77056053` |
| `DUO_WORKFLOW_NAMESPACE_ID` | ネームスペースID。 | `91555435` |
| `DUO_WORKFLOW_GOAL` | フローをトリガーしたイシューのURL。 | `https://gitlab.com/group/project/-/issues/10` |
| `DUO_WORKFLOW_DEFINITION` | フロー定義識別子。 | `developer/v1` |
| `DUO_WORKFLOW_SERVICE_REALM` | デプロイタイプ。 | `saas`または`self-managed` |
| `DUO_WORKFLOW_GIT_HTTP_USER` | クローン作成用のGit HTTPユーザー名。 | `oauth` |
| `DUO_WORKFLOW_GIT_HTTP_PASSWORD` | クローン作成用のGit HTTPパスワード。 | *（OAuthトークン）* |
| `DUO_WORKFLOW_GIT_USER_NAME` | フローをトリガーしたユーザーの名前。Gitコミッターとして使用されます。 | `Jane Developer` |
| `DUO_WORKFLOW_GIT_USER_EMAIL` | フローをトリガーしたユーザーのメール。Gitコミッターのメールとして使用されます。 | `jdeveloper@example.com` |
| `DUO_WORKFLOW_GIT_AUTHOR_EMAIL` | サービスアカウントのメール。Git作成者のメールとして使用されます。 | `service_account_group_<ID>@noreply.gitlab.com` |
| `DUO_WORKFLOW_GIT_AUTHOR_USER_NAME` | サービスアカウントの名前。Git作成者名として使用されます。 | `Duo Developer` |
| `GITLAB_BASE_URL` | GitLabインスタンスのベースURL。`DUO_WORKFLOW_GIT_HTTP_BASE_URL`と同じ値。 | `https://gitlab.com` |
| `GITLAB_PROJECT_PATH` | 名前空間付きのプロジェクトのフルパス。`CI_PROJECT_PATH`と同じ値。 | `my-group/my-project` |
| `GITLAB_TOKEN` | GitLab APIアクセス用のOAuthトークン。`DUO_WORKFLOW_GIT_HTTP_PASSWORD`と同じ値。 | *（OAuthトークン）* |
| `AGENT_PLATFORM_GITLAB_VERSION` | フローを実行しているGitLabバージョン。 | `18.9.0` |

## 利用不可 {#not-available}

フローを実行するジョブでは、以下の変数は使用できません。

### フィルターされた定義済み変数 {#filtered-predefined-variables}

以下の定義済みCI/CD変数は利用できません:

| 変数 | 理由 |
|----------|--------|
| `CI_REGISTRY` | ワークロード変数ゲートによってフィルタリングされます。ハードコードされたレジストリホスト名を使用してください。 |
| `CI_REGISTRY_IMAGE` | ワークロード変数ゲートによってフィルタリングされます。ハードコードされたイメージパスを使用してください。 |
| `CI_SERVER_URL`、`CI_SERVER_HOST`、`CI_API_V4_URL` | フィルタリング。代わりに、`GITLAB_BASE_URL`または`DUO_WORKFLOW_GIT_HTTP_BASE_URL`を使用してください。 |
| `CI_COMMIT_SHA`、`CI_COMMIT_BRANCH`、`CI_COMMIT_REF_NAME` | ジョブにコミットコンテキストがありません。ソースブランチはGitLab Duoエージェントによって管理されます。 |
| `GITLAB_USER_LOGIN`、`GITLAB_USER_EMAIL`、`GITLAB_USER_NAME` | このジョブは、トリガーユーザーではなく、サービスアカウントとして実行されます。 |
| `CI_PIPELINE_SOURCE`、`CI_PIPELINE_IID` | ワークロード変数ゲートによってフィルタリングされます。 |

### ユーザーID {#user-identity}

フロー実行中に使用されるCIジョブトークンは、[複合ID](../composite_identity.md)トークンであり、トリガーユーザーとサービスアカウントの両方を表します。

フロー実行中に作成されたGitコミットは、フローをトリガーしたユーザーによってコミットされますが、サービスアカウントによって作成されたものとしてマークされます。

サービスアカウントがフローを実行しているため、ユーザーではなく、`GITLAB_USER_LOGIN`と`GITLAB_USER_EMAIL`の変数は使用できません。

ただし、フローをトリガーしたユーザーのIDは`DUO_WORKFLOW_GIT_USER_EMAIL`と`DUO_WORKFLOW_GIT_USER_NAME`で使用でき、サービスアカウントのIDは`DUO_WORKFLOW_GIT_AUTHOR_EMAIL`と`DUO_WORKFLOW_GIT_AUTHOR_USER_NAME`で使用できます。

### カスタムCI/CD変数 {#custom-cicd-variables}

**設定 > CI/CD > 変数**で定義されたプロジェクト、グループ、またはインスタンスのカスタムCI/CD変数は使用できません。

カスタムCI/CD変数には、保護された変数、保護されていない変数、マスクされた変数、およびファイル変数が含まれます。

すべてのフロー設定は、`agent-config.yml`または[利用可能な環境変数](#environment-variables)を介して提供する必要があります。

## GitLabインスタンスURLへのアクセス {#accessing-the-gitlab-instance-url}

標準の`CI_SERVER_URL`変数は使用できません。代わりに、`GITLAB_BASE_URL`または`DUO_WORKFLOW_GIT_HTTP_BASE_URL`を使用してください。

たとえば、`setup_script`でAPIコールを行うには:

```yaml
setup_script:
  - "curl --silent --header 'JOB-TOKEN: ${CI_JOB_TOKEN}' ${GITLAB_BASE_URL}/api/v4/projects/${CI_PROJECT_ID}"
```
