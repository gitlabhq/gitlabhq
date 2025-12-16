---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: KubernetesクラスタをGitLabに接続する手順
---

このページでは、単一プロジェクトで基本的なKubernetesインテグレーションをセットアップする方法を説明します。Kubernetes向けGitLabエージェントプルベースのデプロイ、またはFluxを初めて使用する場合は、ここから開始してください。

完了すると、次のことができるようになります:

- リアルタイムのKubernetesダッシュボードでKubernetesクラスタのステータスを表示します。
- Fluxを使用して、クラスタにアップデートをデプロイします。
- GitLab CI/CDを使用して、クラスタにアップデートをデプロイします。

## はじめる前 {#before-you-begin}

このチュートリアルを完了する前に、以下があることを確認してください:

- `kubectl`でローカルにアクセスできるKubernetesクラスタ。KubernetesのどのバージョンをGitLabがサポートしているかについては、[GitLab機能でサポートされているKubernetesのバージョン](_index.md#supported-kubernetes-versions-for-gitlab-features)を参照してください。

  すべてが正しく設定されていることを確認するには、次を実行します:

  ```shell
  kubectl cluster-info
  ```

## Fluxをインストールして設定します {#install-and-configure-flux}

[Flux](https://fluxcd.io/flux/)は、GitOpsデプロイ（プルベースのデプロイとも呼ばれます）に推奨されるツールです。Fluxは成熟したCNCFプロジェクトです。

Fluxをインストールするには:

- Fluxドキュメントの[Flux CLIをインストール](https://fluxcd.io/flux/installation/#install-the-flux-cli)の手順を完了します。

Flux CLIが正しくインストールされていることを確認するには、次を実行します:

```shell
flux -v
```

### パーソナルアクセストークンを作成する {#create-a-personal-access-token}

Flux CLIで認証するには、`api`スコープを持つパーソナルアクセストークンを作成します:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. **パーソナルアクセストークン**を選択します。
1. トークンの名前とオプションの有効期限を入力します。
1. `api`スコープを選択します。
1. **Create personal access token**（パーソナルアクセストークンを作成）を選択します。

`api`スコープと`maintainer`ロールを持つ[プロジェクト](../../project/settings/project_access_tokens.md)または[グループアクセストークン](../../group/settings/group_access_tokens.md)を使用することもできます。

### Fluxをブートストラップ {#bootstrap-flux}

このセクションでは、[`flux bootstrap`](https://fluxcd.io/flux/installation/bootstrap/gitlab/)コマンドを使用して、空のGitLabリポジトリにFluxをブートストラップします。

Fluxインストールをブートストラップするには:

- `flux bootstrap gitlab`コマンドを実行します。例: 

  ```shell
  flux bootstrap gitlab \
  --hostname=gitlab.example.org \
  --owner=my-group/optional-subgroup \
  --repository=my-repository \
  --branch=main \
  --path=clusters/testing \
  --deploy-token-auth
  ```

`bootstrap`の引数は次のとおりです:

| 引数     | 説明 |
|--------------|-------------|
| `hostname`   | GitLabインスタンスのホスト名。 |
| `owner`      | Fluxリポジトリを含むGitLabグループ。 |
| `repository` | Fluxリポジトリを含むGitLabプロジェクト。 |
| `branch`     | 変更をコミットするブランチ。 |
| `path`       | Fluxの設定が保存されているフォルダーへのパス。 |

ブートストラップスクリプトは、次のことを行います:

1. デプロイトークンを作成し、Kubernetes `secret`として保存します。
1. `--repository`引数で指定されたプロジェクトが存在しない場合は、空のGitLabプロジェクトを作成します。
1. `--path`引数で指定されたフォルダーに、プロジェクトのFlux定義ファイルを生成します。
1. `--branch`引数で指定されたブランチに定義ファイルをコミットします。
1. 定義ファイルをクラスタに適用します。

スクリプトを実行すると、FluxはGitLabプロジェクトとパスに追加した他のリソースを自身で管理できるようになります。

このチュートリアルの残りの部分では、パスが`clusters/testing`、プロジェクトが`my-group/optional-subgroup/my-repository`の下にあることを前提としています。

## エージェント接続をセットアップ {#set-up-the-agent-connection}

クラスタを接続するには、Kubernetes向けGitLabエージェントをインストールする必要があります。これは、GitLab CLI（`glab`）でエージェントをブートストラップすることで実行できます。

1. [GitLab CLIをインストール](https://gitlab.com/gitlab-org/cli/#installation)。

   GitLab CLIが利用可能であることを確認するには、以下を実行します。

   ```shell
   glab version
   ```

1. GitLabインスタンスに対して[認証`glab`](https://gitlab.com/gitlab-org/cli/#installation)します。

1. Fluxをブートストラップしたリポジトリで、`glab cluster agent bootstrap`コマンドを実行します:

   ```shell
   glab cluster agent bootstrap --manifest-path clusters/testing testing
   ```

デフォルトでは、コマンドは以下の動作を行います:

1. `testing`を名前としてエージェントを登録します。
1. エージェントを設定します。
1. `testing`という名前のエージェントのダッシュボードで環境を設定します。
1. エージェントトークンを作成します。
1. クラスター内に、エージェントトークンでKubernetesシークレットを作成します。
1. Flux HelmリソースをGitリポジトリにコミットします。
1. Fluxの調整をトリガーします。

エージェントの設定の詳細については、[Kubernetes用エージェントのインストール](install/_index.md)を参照してください。

## Kubernetesのダッシュボードをチェックアウト {#check-out-the-dashboard-for-kubernetes}

`glab cluster agent bootstrap`は、GitLab内に環境を作成し、[設定されたダッシュボード](../../../ci/environments/kubernetes_dashboard.md)を作成しました。

ダッシュボードを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作** > **環境**を選択します。
1. 環境を選択します。たとえば`flux-system/gitlab-agent`などです。
1. **Kubernetesの概要**タブを選択します。

## デプロイを保護する {#secure-the-deployment}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

これまでのところ、`.gitlab/agents/testing/config.yaml`ファイルを使用してエージェントをデプロイしました。この設定により、エージェントのデプロイ用に設定されたサービスアカウントを使用して、ユーザーがアクセスできるようになります。ユーザーアクセスは、Kubernetesのダッシュボード、およびローカルアクセスで使用されます。

デプロイメントのセキュリティを維持するために、GitLabユーザーを代理するようにこの設定を変更する必要があります。この場合、通常のKubernetesのロールベースのアクセス制御（RBAC）を使用して、クラスターリソースへのアクセスを管理できます。

ユーザーの代理を有効にするには、次のようにします:

1. `.gitlab/agents/testing/config.yaml`ファイルで、`user_access.access_as.agent: {}`を`user_access.access_as.user: {}`に置き換えます。
1. Kubernetes用に設定されたダッシュボードに移動します。アクセスが制限されている場合、ダッシュボードにエラーメッセージが表示されます。
1. 次のコードを`clusters/testing/gitlab-user-read.yaml`に追加します:

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
      name: gitlab-user-view
   roleRef:
      name: view
      kind: ClusterRole
      apiGroup: rbac.authorization.k8s.io
   subjects:
      - name: gitlab:user
        kind: Group
   ```

1. Fluxが追加されたマニフェストを適用できるように数秒待ってから、Kubernetesのダッシュボードをもう一度確認します。ダッシュボードは、GitLabのすべてのユーザーに読み取りアクセス権を付与するデプロイされたクラスターロールバインディングのおかげで、正常に戻るはずです。

ユーザーアクセスの詳細については、[Kubernetesへのユーザーアクセス権の付与](user_access.md)を参照してください。

## すべてを最新の状態に保つ {#keep-everything-up-to-date}

インストール後、Fluxと`agentk`をアップグレードする必要があるかもしれません。

これを行うには、次の手順を実行します:

- `flux bootstrap gitlab`コマンドと`glab cluster agent bootstrap`コマンドを再実行します。

## 次の手順 {#next-steps}

エージェントを登録し、Fluxのマニフェストを保存したプロジェクトから、クラスターに直接デプロイできます。エージェントはマルチテナントをサポートするように設計されており、設定されたエージェントとFluxのインストールにより、他のプロジェクトやグループにスケールできます。

フォローアップチュートリアルである[Kubernetesへのデプロイを開始する](getting_started_deployments.md)を行うことを検討してください。GitLabでKubernetesを使用する方法の詳細については、以下を参照してください:

- [KubernetesでのGitLabインテグレーション使用に関するベストプラクティス](enterprise_considerations.md)
- [運用コンテナスキャン](vulnerabilities.md)にエージェントを使用する
- エンジニアに[リモートワークスペース](../../workspace/_index.md)を提供する
