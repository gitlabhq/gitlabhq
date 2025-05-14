---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetes クラスターで GitLab CI/CD を使用する
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- エージェント接続共有制限が、GitLab 17.0 で 100 から [500 に変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149844)。

{{< /history >}}

GitLab CI/CD を使用して、Kubernetes クラスターに安全に接続、デプロイ、および更新できます。

そのためには、[クラスターにエージェントをインストール](install/_index.md)します。完了すると、Kubernetes コンテキストが作成され、GitLab CI/CD パイプラインで Kubernetes API コマンドを実行できます。

クラスターへのアクセスを安全にするには:

- 各エージェントには、個別のコンテキスト (`kubecontext`) があります。
- エージェントが Configure されているプロジェクトと、承認した追加のプロジェクトのみが、クラスター内のエージェントにアクセスできます。

GitLab CI/CD を使用してクラスターとやり取りするには、Runnerを GitLab にregisterする必要があります。ただし、これらの Runner は、エージェントが存在するクラスター内にある必要はありません。

前提要件:

- [GitLab CI/CD が有効になっている](../../../ci/pipelines/settings.md#disable-gitlab-cicd-pipelines)ことを確認してください。

## クラスターで GitLab CI/CD を使用する

GitLab CI/CD を使用して Kubernetes クラスターを更新するには:

1. Kubernetes クラスターが動作しており、manifestが GitLabプロジェクトにあることを確認します。
1. 同じ GitLabプロジェクトで、[GitLabエージェントを register してインストール](install/_index.md)します。
1. [`.gitlab-ci.yml` ファイルを更新](#update-your-gitlab-ciyml-file-to-run-kubectl-commands)して、エージェントの Kubernetes コンテキストを選択し、Kubernetes API コマンドを実行します。
1. パイプラインを実行して、クラスターにデプロイするか、クラスターを更新します。

Kubernetes manifest を含む複数の GitLabプロジェクトがある場合:

1. 独自のプロジェクトで、または Kubernetes manifest を保持する GitLabプロジェクトの 1 つで[GitLabエージェントをインストール](install/_index.md)します。
1. GitLabプロジェクトにアクセスするように[エージェントを承認](#authorize-the-agent)します。
1. 任意。セキュリティを強化するには、[代理を使用](#restrict-project-and-group-access-by-using-impersonation)します。
1. [`.gitlab-ci.yml` ファイルを更新](#update-your-gitlab-ciyml-file-to-run-kubectl-commands)して、エージェントの Kubernetes コンテキストを選択し、Kubernetes API コマンドを実行します。
1. パイプラインを実行して、クラスターにデプロイするか、クラスターを更新します。

## エージェントを承認する

複数の GitLabプロジェクトがある場合は、Kubernetes manifest を保持するプロジェクトにアクセスするようにエージェントを承認する必要があります。エージェントが個々のプロジェクトにアクセスできるように承認することも、グループまたはサブグループを承認して、その中のすべてのプロジェクトがアクセスできるようにすることもできます。セキュリティを強化するために、[代理を使用](#restrict-project-and-group-access-by-using-impersonation)することもできます。

認証設定が反映されるまでに 1 ～ 2 分かかることがあります。

### プロジェクトにアクセスするようにエージェントを承認する

{{< history >}}

- GitLab 15.6 で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/346566)され、階層制限が削除されました。
- GitLab 15.7 でユーザーネームスペース内のプロジェクトを承認できるように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/356831)されました。

{{< /history >}}

Kubernetes manifest を保持する GitLabプロジェクトにアクセスするようにエージェントを承認するには:

1. 左側のサイドバーで、**検索または移動**を選択し、[エージェント設定ファイル](install/_index.md#create-an-agent-configuration-file) (`config.yaml`) を含むプロジェクトを見つけます。
1. `config.yaml`ファイルを編集します。`ci_access`キーワードの下に、`projects`属性を追加します。
1. `id`には、プロジェクトへのパスを追加します。

   ```yaml
   ci_access:
     projects:
       - id: path/to/project
   ```

   - 承認されたプロジェクトは、エージェントの設定プロジェクトと同じトップレベルグループまたはユーザーネームスペースを持っている必要があります。
   - 追加の階層に対応するために、同じクラスターに追加のエージェントをインストールできます。
   - 最大 500 個のプロジェクトを承認できます。

すべての CI/CD ジョブに、すべての共有エージェント接続のコンテキストを含む `kubeconfig` ファイルが含まれるようになりました。`kubeconfig`パスは、環境変数`$KUBECONFIG`で使用できます。CI/CD スクリプトから`kubectl`コマンドを実行するコンテキストを選択します。

### グループ内のプロジェクトにアクセスするようにエージェントを承認する

{{< history >}}

- GitLab 15.6 で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/346566)され、階層制限が削除されました。

{{< /history >}}

グループまたはサブグループ内のすべての GitLabプロジェクトにアクセスするようにエージェントを承認するには:

1. 左側のサイドバーで、**検索または移動**を選択し、[エージェント設定ファイル](install/_index.md#create-an-agent-configuration-file) (`config.yaml`) を含むプロジェクトを見つけます。
1. `config.yaml`ファイルを編集します。`ci_access`キーワードの下に、`groups`属性を追加します。
1. `id`には、パスを追加します:

   ```yaml
   ci_access:
     groups:
       - id: path/to/group/subgroup
   ```

   - 承認されたグループは、エージェントの設定プロジェクトと同じトップレベルグループを持っている必要があります。
   - 追加の階層に対応するために、同じクラスターに追加のエージェントをインストールできます。
   - 承認されたグループのすべてのサブグループも、（個別に指定されなくても）同じエージェントにアクセスできます。
   - 最大 500 個のグループを承認できます。

グループとそのサブグループに属するすべてのプロジェクトが、エージェントにアクセスできるようになりました。すべての CI/CD ジョブに、すべての共有エージェント接続のコンテキストを含む `kubeconfig` ファイルが含まれるようになりました。`kubeconfig`パスは、環境変数`$KUBECONFIG`で使用できます。CI/CD スクリプトから`kubectl`コマンドを実行するコンテキストを選択します。

## `.gitlab-ci.yml`ファイルを更新して`kubectl`コマンドを実行する

Kubernetes コマンドを実行するプロジェクトで、プロジェクトの`.gitlab-ci.yml`ファイルを編集します。

`script`キーワードの下の最初のコマンドで、エージェントのコンテキストを設定します。`<path/to/agent/project>:<agent-name>`形式を使用します。次に例を示します:

```yaml
deploy:
  image:
    name: bitnami/kubectl:latest
    entrypoint: ['']
  script:
    - kubectl config get-contexts
    - kubectl config use-context path/to/agent/project:agent-name
    - kubectl get pods
```

エージェントのコンテキストが不明な場合は、エージェントにアクセスする CI/CD ジョブから`kubectl config get-contexts`を実行します。

### Auto DevOps を使用する環境

Auto DevOps が有効になっている場合は、CI/CD変数`KUBE_CONTEXT`を定義する必要があります。Auto DevOps で使用するエージェントのコンテキストに`KUBE_CONTEXT`の値を設定します:

```yaml
deploy:
  variables:
    KUBE_CONTEXT: path/to/agent/project:agent-name
```

異なるエージェントを別々の Auto DevOps ジョブに割り当てることができます。インスタンスのために、Auto DevOps では、`staging`ジョブに 1 つのエージェントを使用し、`production`ジョブに別のエージェントを使用できます。複数のエージェントを使用するには、各エージェントに[環境スコープの CI/CD変数](../../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)を定義します。次に例を示します:

1. `KUBE_CONTEXT`という名前の 2 つの変数を定義します。
1. 最初の変数:
   1. `environment`を`staging`に設定します。
   1. 値をステージエージェントのコンテキストに設定します。
1. 2 番目の変数:
   1. `environment`を`production`に設定します。
   1. 値を本番環境エージェントのコンテキストに設定します。

### 証明書ベースの接続とエージェントベースの接続の両方を使用する環境

[証明書ベースのクラスター](../../infrastructure/clusters/_index.md)（非推奨）とエージェント接続の両方がある環境にデプロイする場合:

- 証明書ベースのクラスターのコンテキストは`gitlab-deploy`と呼ばれます。このコンテキストは、デフォルトで常に選択されます。
- エージェントのコンテキストは`$KUBECONFIG`に含まれています。それらは`kubectl config use-context <path/to/agent/project>:<agent-name>`を使用して選択できます。

証明書ベースの接続が存在する場合にエージェント接続を使用するには、新しい `kubectl`設定コンテキストを手動で Configure できます。次に例を示します:

```yaml
deploy:
  variables:
    KUBE_CONTEXT: my-context # The name to use for the new context
    AGENT_ID: 1234 # replace with your agent's numeric ID
    K8S_PROXY_URL: https://<KAS_DOMAIN>/k8s-proxy/ # For agent server (KAS) deployed in Kubernetes cluster (for gitlab.com use kas.gitlab.com); replace with your URL
    # K8S_PROXY_URL: https://<GITLAB_DOMAIN>/-/kubernetes-agent/k8s-proxy/ # For agent server (KAS) in Omnibus
    # Include any additional variables
  before_script:
    - kubectl config set-credentials agent:$AGENT_ID --token="ci:${AGENT_ID}:${CI_JOB_TOKEN}"
    - kubectl config set-cluster gitlab --server="${K8S_PROXY_URL}"
    - kubectl config set-context "$KUBE_CONTEXT" --cluster=gitlab --user="agent:${AGENT_ID}"
    - kubectl config use-context "$KUBE_CONTEXT"
  # Include the remaining job configuration
```

### 自己署名証明書を使用する KAS を使用する環境

KAS を使用する環境と自己署名証明書を使用する場合は、証明書に署名した認証局（CA）を信頼するように Kubernetes クライアントを Configure する必要があります。

クライアントを Configure するには、次のいずれかを実行します:

- PEM 形式で KAS 証明書を使用して CI/CD変数 `SSL_CERT_FILE` を設定します。
- `--certificate-authority=$KAS_CERTIFICATE`で Kubernetes クライアントを Configure します。ここで、`KAS_CERTIFICATE` は KAS の CA証明書を持つ CI/CD変数です。
- コンテナイメージを更新するか、Runner 経由でマウントして、ジョブコンテナ内の適切な場所に証明書を配置します。
- 推奨されません。`--insecure-skip-tls-verify=true`で Kubernetes クライアントを Configure します。

## 代理を使用してプロジェクトとグループのアクセスを制限する

{{< details >}}

- プラン:Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.5 で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/357934)され、環境プランの代理のサポートが追加されました。

{{< /history >}}

デフォルトでは、CI/CD ジョブは、クラスターにエージェントをインストールするために使用されるサービスアカウントからすべての権限を継承します。クラスターへのアクセスを制限するには、[代理](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation)を使用します。

代理を指定するには、エージェント設定ファイルで`access_as`属性を使用し、Kubernetes RBAC ルールを使用して代理アカウントの権限を管理します。

代理にできるもの:

- エージェント自体（デフォルト）。
- クラスターにアクセスする CI/CD ジョブ。
- クラスター内で定義された特定のユーザーまたはシステムアカウント。

認証設定が反映されるまでに 1 ～ 2 分かかることがあります。

### エージェントを代理化する

エージェントはデフォルトで代理化されます。代理化するために何かする必要はありません。

### クラスターにアクセスする CI/CD ジョブを代理化する

クラスターにアクセスする CI/CD ジョブを代理化するには、`access_as` キーの下に `ci_job: {}` キーと値を追加します。

エージェントが実際の Kubernetes API にリクエストを行う場合、次の方法で代理認証情報を設定します:

- `UserName`が`gitlab:ci_job:<job id>`に設定されます。例：`gitlab:ci_job:1074499489`。
- `Groups`は以下に設定されます:

  - CI ジョブからのすべてのリクエストを識別するために`gitlab:ci_job`。
  - プロジェクトが存在するグループの ID のリスト。
  - プロジェクトID。
  - このジョブが属する環境のslugとプラン。

    `group1/group1-1/project1` の CI ジョブの例:

    - グループ`group1`の ID は 23 です。
    - グループ`group1/group1-1`の ID は 25 です。
    - プロジェクト`group1/group1-1/project1`の ID は 150 です。
    - `production`環境プランを持つ`prod`環境で実行されているジョブ。

  グループリストは`[gitlab:ci_job, gitlab:group:23, gitlab:group_env_tier:23:production, gitlab:group:25, gitlab:group_env_tier:25:production, gitlab:project:150, gitlab:project_env:150:prod, gitlab:project_env_tier:150:production]`になります。

- `Extra`は、リクエストに関する追加情報を伝えます。代理化された ID には、次のプロパティが設定されます:

| プロパティ                             | 説明                                                                  |
| ------------------------------------ | ---------------------------------------------------------------------------- |
| `agent.gitlab.com/id`                | エージェント ID が含まれています。                                                       |
| `agent.gitlab.com/config_project_id` | エージェントの設定プロジェクト ID が含まれています。                               |
| `agent.gitlab.com/project_id`        | CI プロジェクト ID が含まれています。                                                  |
| `agent.gitlab.com/ci_pipeline_id`    | CI パイプライン ID が含まれています。                                                 |
| `agent.gitlab.com/ci_job_id`         | CI ジョブ ID が含まれています。                                                      |
| `agent.gitlab.com/username`          | CI ジョブが実行されているユーザーのユーザー名が含まれています。                  |
| `agent.gitlab.com/environment_slug`  | 環境の slug が含まれています。環境で実行されている場合にのみ設定されます。 |
| `agent.gitlab.com/environment_tier`  | 環境のプランが含まれています。環境で実行されている場合にのみ設定されます。 |

CI/CD ジョブの ID でアクセスを制限する例 `config.yaml`:

```yaml
ci_access:
  projects:
    - id: path/to/project
      access_as:
        ci_job: {}
```

#### CI/CD ジョブを制限する RBAC の例

次の`RoleBinding`リソースは、すべての CI/CD ジョブを読み取り権限のみに制限します。

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ci-job-view
roleRef:
  name: view
  kind: ClusterRole
  apiGroup: rbac.authorization.k8s.io
subjects:
  - name: gitlab:ci_job
    kind: Group
```

### 静的なIDを代理化する

特定の接続では、代理化に静的なIDを使用できます。

`access_as`キーの下に、`impersonate`キーを追加して、提供された ID を使用してリクエストを行います。

ID は、次のキーで指定できます:

- `username` (必須)
- `uid`
- `groups`
- `extra`

詳細については、[Kubernetes の公式ドキュメント](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation)を参照してください。

## 特定の環境へのプロジェクトとグループのアクセスを制限する

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.7 で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/343885)

{{< /history >}}

デフォルトでは、エージェントが[プロジェクトで利用できる](#authorize-the-agent)場合、プロジェクトのすべての CI/CD ジョブはそのエージェントを使用できます。

特定環境でのジョブのみにエージェントへのアクセスを制限するには、`environments`を`ci_access.projects`または`ci_access.groups`に追加します。次に例を示します:

  ```yaml
  ci_access:
    projects:
      - id: path/to/project-1
      - id: path/to/project-2
        environments:
          - staging
          - review/*
    groups:
      - id: path/to/group-1
        environments:
          - production
  ```

この例では:

- `project-1`のすべての CI/CD ジョブがエージェントにアクセスできます。
- `project-2`の`staging`または`review/*`環境下にある CI/CD ジョブはエージェントにアクセスできます。
  - `*`はワイルドカードのため、`review/*`は`review`配下のすべての環境と一致します。
- `group-1`配下のプロジェクトの`production`環境用の CI/CD ジョブは、エージェントにアクセスできます。

## 保護ブランチへのエージェントへのアクセスを制限

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.3 で`kubernetes_agent_protected_branches`という[フラグとともに](../../../administration/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/467936)。デフォルトでは無効。
- GitLab 17.10 で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467936)。機能フラグ `kubernetes_agent_protected_branches` は削除されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能は Test には使用できますが、本番環境での使用には対応していません。

{{< /alert >}}

[保護ブランチ](../../project/repository/branches/protected.md)で実行されるジョブのみにエージェントへのアクセスを制限するには:

- `protected_branches_only: true`を`ci_access.projects`または`ci_access.groups`に追加します。次に例を示します:

  ```yaml
  ci_access:
    projects:
      - id: path/to/project-1
        protected_branches_only: true
    groups:
      - id: path/to/group-1
        protected_branches_only: true
        environments:
          - production
  ```

デフォルトでは、`protected_branches_only`が`false`に設定され、エージェントには保護されていないブランチと保護ブランチからアクセスできます。

セキュリティを強化するために、この機能を[環境制限](#restrict-project-and-group-access-to-specific-environments)と組み合わせることができます。

プロジェクトに複数の設定がある場合、最も具体的な設定のみが使用されます。たとえば、次の設定では、`example` グループが保護ブランチへのアクセスのみを許可するように Configure されている場合でも、`example/my-project` の保護されていないブランチへのアクセスが許可されます:

```yaml
# .gitlab/agents/my-agent/config.yaml
ci_access:
  project:
    - id: example/my-project # Project of the group below
      protected_branches_only: false # This configuration supercedes the group configuration
      environments:
        - dev
  groups:
    - id: example
      protected_branches_only: true
      environments:
        - dev
```

詳細については、[CI/CD から Kubernetes へのアクセス](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_ci_access.md#apiv4joballowed_agents-api)を参照してください。

## 関連トピック

- [自己ペースの教室ワークショップ](https://gitlab-for-eks.awsworkshop.io) (AWS EKS を使用していますが、他の Kubernetes クラスターにも使用できます)
- [Auto DevOps を Configure する](../../../topics/autodevops/cloud_deployments/auto_devops_with_gke.md#configure-auto-devops)

## トラブルシューティング

### `~/.kube/cache` に書き込み権限を付与する

`kubectl`、Helm、`kpt`、`kustomize`などのツールは、クラスターに関する情報を`~/.kube/cache`にキャッシュします。このディレクトリが書き込み可能でない場合、ツールは呼び出すたびに情報をフェッチするため、インタラクションが遅くなり、クラスターの読み込みに不要な負荷がかかります。最良のエクスペリエンスを得るために、`.gitlab-ci.yml` ファイルで使用するイメージで、このディレクトリが書き込み可能であることを確認してください。

### TLS を有効にする

GitLab Self-Managed を使用している場合は、インスタンスがトランスポートレイヤーセキュリティ（TLS）で Configure されていることを確認してください。

TLS なしで`kubectl`を使用しようとすると、次のようなエラーが発生する可能性があります:

```shell
$ kubectl get pods
error: You must be logged in to the server (the server has asked for the client to provide credentials)
```

### サーバーに接続できません: 不明な作成者によって署名された証明書

KAS を使用する環境と自己署名証明書を使用する場合、`kubectl` 呼び出しで次のエラーが返される可能性があります:

```plaintext
kubectl get pods
Unable to connect to the server: x509: certificate signed by unknown authority
```

このエラーは、ジョブが KAS 証明書に署名した認証局（CA）を信頼しないために発生します。

イシューを解決するには、[CA を信頼するように `kubectl` を Configure ](#environments-with-kas-that-use-self-signed-certificates)します。

### 検証エラー

`kubectl`バージョン v1.27.0 または v.1.27.1 を使用している場合、次のエラーが発生する可能性があります:

```plaintext
error: error validating "file.yml": error validating data: the server responded with the status code 426 but did not return more information; if you choose to ignore these errors, turn validation off with --validate=false
```

このイシューは、共有 Kubernetes ライブラリを使用する`kubectl`およびその他のツールの[バグ](https://github.com/kubernetes/kubernetes/issues/117463)によって発生します。

イシューを解決するには、別のバージョンの`kubectl`を使用します。
