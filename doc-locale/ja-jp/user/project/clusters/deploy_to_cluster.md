---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: クラスター証明書を使用したKubernetesクラスターへのデプロイ (非推奨)
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。クラスターをGitLabに接続するには、[Kubernetes向けGitLabエージェント](../../clusters/agent/_index.md)を使用します。エージェントを使用してデプロイするには、[CI/CDワークフロー](../../clusters/agent/ci_cd_workflow.md)を使用します。

{{< /alert >}}

Kubernetesクラスターは、デプロイメントジョブの宛先になることがあります。次の場合:

- クラスターがGitLabとインテグレーションされている場合、特別な[deployment variable](#deployment-variables)がジョブで使用できるようになり、設定は不要です。`kubectl`や`helm`などのツールを使用して、ジョブからクラスターとのインテグレーションをすぐに開始できます。
- GitLabクラスターインテグレーションを使用しない場合でも、クラスターにデプロイできます。ただし、ジョブからクラスターとのインテグレーションを行う前に、[CI/CD変数](../../../ci/variables/_index.md#for-a-project)を使用してKubernetesツールを自分で設定する必要があります。

## デプロイ変数 {#deployment-variables}

デプロイメント変数では、[デプロイトークン](../deploy_tokens/_index.md)という名前の有効な[`gitlab-deploy-token`](../deploy_tokens/_index.md#gitlab-deploy-token)が必要です。また、Kubernetesがレジストリにアクセスできるようにするには、デプロイメントジョブスクリプトに次のコマンドが必要です:

- Kubernetes 1.18以降を使用する場合:

  ```shell
  kubectl create secret docker-registry gitlab-registry --docker-server="$CI_REGISTRY" --docker-username="$CI_DEPLOY_USER" --docker-password="$CI_DEPLOY_PASSWORD" --docker-email="$GITLAB_USER_EMAIL" -o yaml --dry-run=client | kubectl apply -f -
  ```

- Kubernetes 1.18より前のバージョンを使用する場合:

  ```shell
  kubectl create secret docker-registry gitlab-registry --docker-server="$CI_REGISTRY" --docker-username="$CI_DEPLOY_USER" --docker-password="$CI_DEPLOY_PASSWORD" --docker-email="$GITLAB_USER_EMAIL" -o yaml --dry-run | kubectl apply -f -
  ```

Kubernetesクラスターインテグレーションは、これらの[deployment variable](../../../ci/variables/predefined_variables.md#deployment-variables)をGitLab CI/CDビルド環境でデプロイメントジョブに公開します。デプロイメントジョブには、[定義されたターゲット環境](../../../ci/environments/_index.md)があります。

| デプロイ変数        | 説明 |
|----------------------------|-------------|
| `KUBE_URL`                 | API URLと同じです。 |
| `KUBE_TOKEN`               | [環境サービスアカウント](cluster_access.md)のKubernetesトークン。 |
| `KUBE_NAMESPACE`           | プロジェクトのデプロイサービスアカウントに関連付けられたネームスペース。`<project_name>-<project_id>-<environment>`形式を使用します。GitLab管理対象クラスターの場合、一致するネームスペースは、GitLabによってクラスター内に自動的に作成されます。クラスターがGitLab 12.2より前に作成された場合、`KUBE_NAMESPACE`のデフォルトは`<project_name>-<project_id>`に設定されます。 |
| `KUBE_CA_PEM_FILE`         | PEMデータを含むファイルへのパス。カスタム認証局バンドルが指定されている場合にのみ存在します。 |
| `KUBE_CA_PEM`              | （**非推奨**）raw PEMデータ。カスタム認証局バンドルが指定されている場合にのみ。 |
| `KUBECONFIG`               | このデプロイ用の`kubeconfig`を含むファイルへのパス。認証局バンドルは、指定されていれば埋め込まれます。この設定には、`KUBE_TOKEN`で定義されたものと同じトークンも埋め込まれているため、おそらくこの変数のみが必要です。この変数名は`kubectl`によって自動的に選択されるため、`kubectl`を使用している場合は明示的に参照する必要はありません。 |
| `KUBE_INGRESS_BASE_DOMAIN` | この変数は、クラスターごとにドメインを設定するために使用できます。詳細については、[クラスタードメイン](gitlab_managed_clusters.md#base-domain)を参照してください。 |

## カスタムネームスペース {#custom-namespace}

Kubernetesインテグレーションは、自動生成されたネームスペースを持つ`KUBECONFIG`をデプロイメントジョブに提供します。これは、`<prefix>-<environment>`という形式のプロジェクト環境固有のネームスペースを使用するようにデフォルト設定されています。ここで、`<prefix>`は`<project_name>-<project_id>`という形式です。詳細については、[デプロイ変数](#deployment-variables)を参照してください。

いくつかの方法でデプロイネームスペースをカスタマイズできます:

- **ネームスペースを[環境](../../../ci/environments/_index.md)ごとに**するか、**プロジェクトごとにする**かを選択できます。環境ごとのネームスペースは、本番環境と非本番環境間でリソースが混在するのを防ぐため、デフォルトの推奨設定です。
- プロジェクトレベルのクラスターを使用する場合、さらにネームスペースプレフィックスをカスタマイズできます。ネームスペースごとの環境を使用する場合、デプロイネームスペースは`<prefix>-<environment>`ですが、それ以外の場合は`<prefix>`のみです。
- **non-managed**（非管理対象） クラスターの場合、自動生成されたネームスペースは`KUBECONFIG`に設定されますが、ユーザーはその存在を確認する必要があります。`.gitlab-ci.yml`の[`environment:kubernetes:namespace`](../../../ci/environments/configure_kubernetes_deployments.md)を使用して、この値を完全にカスタマイズできます。

ネームスペースをカスタマイズすると、[クラスターキャッシュをクリア](gitlab_managed_clusters.md#clearing-the-cluster-cache)するまで、既存の環境は現在のネームスペースにリンクされたままになります。

### 認証情報の保護 {#protecting-credentials}

デフォルトでは、デプロイメントジョブを作成できるユーザーは誰でも、環境のデプロイメントジョブ内の任意のCI/CD変数にアクセスできます。これには、クラスター内の関連付けられたサービスアカウントで使用可能なすべてのシークレットへのアクセスを提供する`KUBECONFIG`が含まれます。本番環境認証情報を安全に保つために、次のいずれかと組み合わせて、[protected environment](../../../ci/environments/protected_environments.md)の使用を検討してください:

- GitLab管理対象クラスターと環境ごとのネームスペース。
- 保護環境ごとの環境スコープクラスター。同じクラスターを、複数の制限されたサービスアカウントで複数回追加できます。

## KubernetesクラスターのWeb端末 {#web-terminals-for-kubernetes-clusters}

Kubernetesインテグレーションにより、[Web端末](../../../ci/environments/_index.md#web-terminals-deprecated)のサポートが[環境](../../../ci/environments/_index.md)に追加されます。これはDockerとKubernetesにある`exec`機能に基づいているため、既存のコンテナに新しいシェルセッションが表示されます。このインテグレーションを使用するには、このページのデプロイメント変数を使用してKubernetesにデプロイする必要があります。これにより、すべてのデプロイ、レプリカセット、およびポッドに次の注釈が付けられるようになります:

- `app.gitlab.com/env: $CI_ENVIRONMENT_SLUG`
- `app.gitlab.com/app: $CI_PROJECT_PATH_SLUG`

`$CI_ENVIRONMENT_SLUG`と`$CI_PROJECT_PATH_SLUG`は、CI/CD変数の値です。

ターミナルを使用するには、プロジェクトオーナーであるか、`maintainer`権限を持っている必要があります。サポートは、環境の最初のポッド内の最初のコンテナに限定されています。

## トラブルシューティング {#troubleshooting}

デプロイメントジョブが開始される前に、GitLabは、特にデプロイメントジョブのために次のものを作成します:

- ネームスペース。
- サービスアカウント。

ただし、GitLabがそれらを作成できない場合があります。そのようなインスタンスでは、ジョブが次のメッセージで失敗する可能性があります:

```plaintext
This job failed because the necessary resources were not successfully created.
```

ネームスペースとサービスアカウントの作成時にこのエラーの原因を特定するには、[ログ](../../../administration/logs/_index.md#kuberneteslog-deprecated)を確認してください。

失敗の理由としては、次のものがあります:

- GitLabに提供したトークンに、GitLabに必要な[`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)権限がありません。
- `KUBECONFIG`または`KUBE_TOKEN`のデプロイメント変数がありません。ジョブに渡されるには、一致する[`environment:name`](../../../ci/environments/_index.md)が必要です。ジョブに`environment:name`が設定されていない場合、Kubernetes認証情報は渡されません。

{{< alert type="note" >}}

GitLab 12.0以前からアップグレードされたプロジェクトレベルのクラスターは、このエラーを引き起こす方法で設定されている可能性があります。ネームスペースとサービスアカウントを自分で管理する場合は、[GitLab管理のクラスター](gitlab_managed_clusters.md)オプションをオフにしてください。

{{< /alert >}}
