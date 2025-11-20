---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab管理のKubernetesリソース
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.9で`gitlab_managed_cluster_resources`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/16130)されました。デフォルトでは無効になっています。
- 機能フラグ`gitlab_managed_cluster_resources`は、GitLab 18.1で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/520042)。

{{< /history >}}

GitLab管理のKubernetesリソースを使用して、環境テンプレートでKubernetesリソースをプロビジョニングします。環境テンプレートでできること:

- 新しい環境のネームスペースとサービスアカウントを自動的に作成します
- ロールバインディングを通じてアクセス許可を管理します
- 必要なその他のKubernetesリソースを構成します

デベロッパーがアプリケーションをデプロイすると、GitLabは環境テンプレートに基づいてリソースを作成します。

## GitLab管理のKubernetesリソースの設定 {#configure-gitlab-managed-kubernetes-resources}

前提要件: 

- 構成済みの[Kubernetes向けGitLabエージェント](install/_index.md)が必要です。
- 関連するプロジェクトまたはグループにアクセスするために[エージェントを承認](ci_cd_workflow.md#authorize-agent-access)しました。
- （オプション）特権エスカレーションを防ぐために[代理エージェント](ci_cd_workflow.md#restrict-project-and-group-access-by-using-impersonation)を構成しました。デフォルトの環境テンプレートは、[`ci_job`代理](ci_cd_workflow.md#impersonate-the-cicd-job-that-accesses-the-cluster)が構成されていることを前提としています。

### Kubernetesリソース管理を有効にする {#turn-on-kubernetes-resource-management}

#### エージェント設定ファイル内 {#in-your-agent-configuration-file}

リソース管理を有効にするには、必要な権限を含めるようにエージェント設定ファイルを変更します:

```yaml
ci_access:
  projects:
    - id: <your_group/your_project>
      access_as:
        ci_job: {}
      resource_management:
        enabled: true
  groups:
    - id: <your_other_group>
      access_as:
        ci_job: {}
      resource_management:
        enabled: true
```

#### CI/CDジョブ内 {#in-your-cicd-jobs}

エージェントが環境のリソースを管理できるようにするには、デプロイメントジョブでエージェントを指定します。例: 

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    kubernetes:
      agent: path/to/agent/project:agent-name
```

CI/CD変数は、エージェントパスで使用できます。詳細については、[変数が使用できる場所](../../../ci/variables/where_variables_can_be_used.md)を参照してください。

### 環境テンプレートの作成 {#create-environment-templates}

環境テンプレートは、作成、更新、または削除されるKubernetesリソースを定義します。

[デフォルト環境テンプレート](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/managed_resources/server/default_template.yaml)は、`Namespace`を作成し、CI/CDジョブの`RoleBinding`を構成します。

デフォルトのテンプレートを上書きするには、`default.yaml`というテンプレート設定ファイルをエージェントディレクトリに追加します:

```plaintext
.gitlab/agents/<agent-name>/environment_templates/default.yaml
```

#### サポートされているKubernetesリソース {#supported-kubernetes-resources}

次のKubernetesリソース（`kind`）がサポートされています:

- `Namespace`
- `ServiceAccount`
- `RoleBinding`
- FluxCDソースコントローラーオブジェクト:
  - `GitRepository`
  - `HelmRepository`
  - `HelmChart`
  - `Bucket`
  - `OCIRepository`
- FluxCD Kustomizeコントローラーオブジェクト:
  - `Kustomization`
- FluxCD Helmコントローラーオブジェクト:
  - `HelmRelease`
- FluxCD通知コントローラーオブジェクト:
  - `Alert`
  - `Provider`
  - `Receiver`

#### 環境テンプレートの例 {#example-environment-template}

次の例では、ネームスペースを作成し、グループ管理者にクラスタリングへのアクセスを許可します。

```yaml
objects:
  - apiVersion: v1
    kind: Namespace
    metadata:
      name: '{{ .environment.slug }}-{{ .project.id }}-{{ .agent.id }}'
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: bind-{{ .environment.slug }}-{{ .project.id }}-{{ .agent.id }}
      namespace: '{{ .environment.slug }}-{{ .project.id }}-{{ .agent.id }}'
    subjects:
      - kind: Group
        apiGroup: rbac.authorization.k8s.io
        name: gitlab:project_env:{{ .project.id }}:{{ .environment.slug }}
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: admin

# Resource lifecycle configuration
apply_resources: on_start    # Resources are applied when environment is started/restarted
delete_resources: on_stop    # Resources are removed when environment is stopped
```

### テンプレート変数 {#template-variables}

環境テンプレートは、制限された変数の置換をサポートします。次の変数を使用できます:

| カテゴリ       | 変数                      | 説明               | 型    | 設定されていない場合のデフォルト値 |
|----------------|-------------------------------|---------------------------|---------|----------------------------|
| エージェント          | `{{ .agent.id }}`             | エージェントID。             | 整数 | N/A                       |
| エージェント          | `{{ .agent.name }}`           | エージェント名。           | 文字列  | N/A                       |
| エージェント          | `{{ .agent.url }}`            | エージェントURL。            | 文字列  | N/A                       |
| 環境    | `{{ .environment.id }}`       | 環境ID。       | 整数 | N/A                       |
| 環境    | `{{ .environment.name }}`     | 環境名。     | 文字列  | N/A                       |
| 環境    | `{{ .environment.slug }}`     | 環境名に基づいた環境slug。先頭が文字で、`-`で終わらない、`-`を含む最大24個の小文字の英数字。 | 文字列  | N/A                       |
| 環境    | `{{ .environment.url }}`      | 環境URL      | 文字列  | 空の文字列               |
| 環境    | `{{ .environment.page_url }}` | 環境ページURL。 | 文字列  | N/A                       |
| 環境    | `{{ .environment.tier }}`     | 環境の階層     | 文字列  | N/A                       |
| プロジェクト        | `{{ .project.id }}`           | プロジェクトID。           | 整数 | N/A                       |
| プロジェクト        | `{{ .project.slug }}`         | プロジェクトのslug。これは、プロジェクトパスの変更されていない最後のコンポーネントです。        | 文字列  | N/A                       |
| プロジェクト        | `{{ .project.path }}`         | プロジェクトパス。         | 文字列  | N/A                       |
| プロジェクト        | `{{ .project.url }}`          | プロジェクトURL。          | 文字列  | N/A                       |
| CI/CDパイプライン | `{{ .ci_pipeline.id }}`       | パイプラインID。          | 整数 | ゼロ                       |
| CI/CDジョブ      | `{{ .ci_job.id }}`            | CI/CDジョブID。         | 整数 | ゼロ                       |
| ユーザー           | `{{ .user.id }}`              | ユーザーID。              | 整数 | N/A                       |
| ユーザー           | `{{ .user.username }}`        | ユーザー名。             | 文字列  | N/A                       |
| ネームスペース      | `{{ .legacy_namespace }}`     | この環境用に非推奨の証明書ベースのクラスター統合で生成されていたKubernetesネームスペース。このネームスペースは、証明書ベースのクラスター統合からGitLab管理のリソースへの移行のみを目的としています。他の目的で使用しないでください。 | 文字列 | N/A |

すべての変数は、二重波括弧構文を使用して参照する必要があります（例：`{{ .project.id }}`）。使用されているテンプレートシステムの詳細については、[`text/template`](https://pkg.go.dev/text/template)ドキュメントを参照してください。

### テンプレート関数 {#template-functions}

環境テンプレートは、変数の値を操作するための制限された関数をサポートしています。次の関数を使用できます:

| 名前         | 引数                | 説明                                          | 例                                    |
|--------------|--------------------------|------------------------------------------------------|--------------------------------------------|
| `lower`      | `<string>`               | 小文字に変換します。                               | `lower "HELLO"` -> `"hello"`               |
| `substr`     | `<start> <end> <string>` | 文字列からサブストリングを取得します。                      | `substr 0 5 "hello world"` -> `"hello"`    |
| `replace`    | `<old> <new> <string>`   | 文字列内のサブストリングのすべての出現箇所を置き換えます。 | `replace "_" "-" "foo_bar"` -> `"foo-bar"` |
| `trimPrefix` | `<prefix> <string>`      | 文字列からプレフィックスを削除します。                   | `trimPrefix "-" "-hello"` -> `"hello"`     |
| `trimSuffix` | `<suffix> <string>`      | 文字列からサフィックスを削除します。                   | `trimSuffix "-" "hello-"` -> `"hello"`   |
| `slugify`    | `[<len>] <string>`       | RFC1123に従って、指定された文字列をスラグ化します。デフォルトでは、`63`文字にトリムします。 | `slugify "hello WORLD"` -> `"hello-world"`   |

変数をKubernetes値に準拠させるために、関数の数は、ネームスペース名やラベルなど、意図的に最小限の関数セットに制限されています。

### リソースライフサイクル管理 {#resource-lifecycle-management}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/507486)されました。

{{< /history >}}

Kubernetesリソースを削除するタイミングを構成するには、次の設定を使用します:

```yaml
# Never delete resources
delete_resources: never

# Delete resources when environment is stopped
delete_resources: on_stop
```

デフォルト値は`on_stop`であり、[デフォルト環境テンプレート](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/managed_resources/server/default_template.yaml)で指定されています。

### 管理対象リソースのラベルと注釈 {#managed-resource-labels-and-annotations}

GitLabによって作成されたリソースは、追跡とトラブルシューティングの目的で一連のラベルと注釈を使用します。

次のラベルは、GitLabによって作成されたすべてのリソースで定義されています。値は意図的に空のままになっています:

- `agent.gitlab.com/id-<agent_id>: ""`
- `agent.gitlab.com/project_id-<project_id>: ""`
- `agent.gitlab.com/env-<gitlab_environment_slug>-<project_id>-<agent_id>: ""`
- `agent.gitlab.com/environment_slug-<gitlab_environment_slug>: ""`

GitLabによって作成されたすべてのリソースで、`agent.gitlab.com/env-<gitlab_environment_slug>-<project_id>-<agent_id>`注釈が定義されています。注釈の値は、次のキーを持つJSONオブジェクトです:

| キー | 説明                                      |
|-----|--------------------------------------------------|
| `environment_id` | GitLab環境ID。                       |
| `environment_name` | GitLab環境名。                     |
| `environment_slug` | GitLab環境slug。                     |
| `environment_url` | 環境へのリンク。オプション。           |
| `environment_page_url` | GitLab環境ページへのリンク。         |
| `environment_tier` | GitLab環境デプロイ階層。          |
| `agent_id` | エージェントID。                                    |
| `agent_name` | エージェント名。                                  |
| `agent_url` | エージェント登録プロジェクトのエージェントURL。 |
| `project_id` | GitLabプロジェクトID。                           |
| `project_slug` | GitLabプロジェクトslug。                         |
| `project_path` | GitLabプロジェクトのフルパス。                    |
| `project_url` | GitLabプロジェクトへのリンク。                  |
| `template_name` | 使用されるテンプレートの名前。                   |

### GitLabで管理されたKubernetesリソースを無効にする {#disable-gitlab-managed-kubernetes-resources}

ダッシュボードなどの他のKubernetes機能を引き続き使用しながら、特定の環境に対してGitLab管理のKubernetesリソースを無効にすることができます。管理対象リソースを無効にすると、デフォルトで管理対象リソースが有効になっているグローバルエージェントを操作する場合に役立ちますが、特定のプロジェクトまたは環境をオプトアウトする必要があります。

環境の管理対象リソースを無効にするには、`managed_resources.enabled: false`構成を追加します:

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    kubernetes:
      agent: path/to/agent/project:agent-name
      managed_resources:
        enabled: false
```

## トラブルシューティング {#troubleshooting}

管理対象のKubernetesリソースに関連するエラーは、次の場所にあります:

- GitLabプロジェクトの環境ページ
- パイプラインで機能を使用する場合のCI/CDジョブログ
