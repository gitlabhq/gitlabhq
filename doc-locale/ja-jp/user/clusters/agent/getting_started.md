---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: KubernetesクラスターをGitLabに接続する手順
---

このページでは、単一のプロジェクトに基本的なKubernetesのインテグレーションを設定する手順を説明します。Kubernetes向けGitLabエージェント、プルベースのデプロイ、またはFluxを初めて使用する場合は、ここから始めてください。

完了すると、次のことができるようになります:

- リアルタイムのKubernetesダッシュボードで、Kubernetesクラスターのステータスを表示する。
- Fluxを使用して、クラスターに更新をデプロイする。
- GitLab CI/CDを使用して、クラスターに更新をデプロイする。

## はじめる前 {#before-you-begin}

このチュートリアルを完了する前に、以下があることを確認してください:

- `kubectl`を使用してローカルでアクセスできるKubernetesクラスター。KubernetesのどのバージョンがGitLabでサポートされているかを確認するには、[GitLab機能でサポートされるKubernetesバージョン](_index.md#supported-kubernetes-versions-for-gitlab-features)を参照してください。

  すべてが適切に設定されているかは、以下を実行して確認できます:

  ```shell
  kubectl cluster-info
  ```

## Fluxのインストールと設定 {#install-and-configure-flux}

[Flux](https://fluxcd.io/flux/)は、GitOpsデプロイ（プルベースのデプロイとも呼ばれる）に推奨されるツールです。Fluxは成熟したCNCFプロジェクトです。

Fluxをインストールするには:

- Fluxドキュメントの[Flux CLIのインストール](https://fluxcd.io/flux/installation/#install-the-flux-cli)の手順を完了してください。

以下を実行して、Flux CLIが適切にインストールされていることを確認します:

```shell
flux -v
```

### パーソナルアクセストークンを作成する {#create-a-personal-access-token}

Flux CLIで認証するには、`api`スコープを持つパーソナルアクセストークンを作成します:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで、**アクセス** > **パーソナルアクセストークン**を選択します。
1. トークンの名前とオプションの有効期限を入力します。
1. `api`スコープを選択します。
1. **パーソナルアクセストークンを作成**を選択します。

`api`スコープと`maintainer`ロールを持つ[プロジェクト](../../project/settings/project_access_tokens.md)または[グループアクセストークン](../../group/settings/group_access_tokens.md)も使用できます。

### Fluxのブートストラップ {#bootstrap-flux}

このセクションでは、[`flux bootstrap`](https://fluxcd.io/flux/installation/bootstrap/gitlab/)コマンドを使用して、空のGitリポジトリにFluxをブートストラップします。

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
| `branch`     | 変更がコミットされるGitブランチ。 |
| `path`       | Flux設定が保存されるフォルダーへのファイルパス。 |

ブートストラップスクリプトは以下を実行します:

1. デプロイトークンを作成し、Kubernetes `secret`として保存します。
1. `--repository`引数で指定されたGitLabプロジェクトが存在しない場合、空のGitLabプロジェクトを作成します。
1. `--path`引数で指定されたフォルダーに、プロジェクト用のFlux定義ファイルを生成します。
1. `--branch`引数で指定されたブランチに定義ファイルをコミットします。
1. 定義ファイルをクラスターに適用します。

スクリプトを実行すると、Fluxは自身と、GitLabプロジェクトおよびパスに追加するその他のリソースを管理できるようになります。

このチュートリアルの残りの部分では、パスが`clusters/testing`で、プロジェクトが`my-group/optional-subgroup/my-repository`の下にあることを前提としています。

## エージェント接続を設定する {#set-up-the-agent-connection}

クラスターを接続するには、Kubernetes向けGitLabエージェントをインストールする必要があります。これは、GitLab CLI (`glab`) を使用してエージェントをブートストラップすることで実行できます。

1. [GitLab CLI](https://gitlab.com/gitlab-org/cli/#installation)をインストールします。

   GitLab CLIが利用可能であることを確認するには、以下を実行します。

   ```shell
   glab version
   ```

1. GitLabインスタンスに[`glab`を認証します](https://gitlab.com/gitlab-org/cli/#installation)。

1. Fluxをブートストラップしたリポジトリで、`glab cluster agent bootstrap`コマンドを実行します:

   ```shell
   glab cluster agent bootstrap --manifest-path clusters/testing testing
   ```

デフォルトでは、コマンドは以下の動作を行います。

1. `testing`を名前としてエージェントを登録します。
1. エージェントを設定します。
1. `testing`と呼ばれる環境を、エージェント用のダッシュボードと共に設定します。
1. エージェントトークンを作成します。
1. クラスター内に、エージェントトークンでKubernetesシークレットを作成します。
1. Flux HelmリソースをGitリポジトリにコミットします。
1. Fluxの調整をトリガーします。

エージェントの設定の詳細については、[Kubernetes向けエージェントのインストール](install/_index.md)を参照してください。

## Kubernetesのダッシュボードをチェックアウトする {#check-out-the-dashboard-for-kubernetes}

`glab cluster agent bootstrap`はGitLab内に環境を作成し、[ダッシュボードを設定](../../../ci/environments/kubernetes_dashboard.md)しました。

ダッシュボードを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作** > **環境**を選択します。
1. 環境を選択します。例: `flux-system/gitlab-agent`。
1. **Kubernetesの概要**タブを選択します。

## デプロイを保護する {#secure-the-deployment}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

これまでに、`.gitlab/agents/testing/config.yaml`ファイルを使用してエージェントをデプロイしました。この設定により、エージェントデプロイ用に設定されたサービスアカウントを使用してユーザーアクセスが可能になります。ユーザーアクセスはKubernetesのダッシュボードおよびローカルアクセスに使用されます。

デプロイを安全に保つために、この設定をGitLabユーザーの代理に変更する必要があります。この場合、通常のKubernetesロールベースのアクセス制御 (RBAC) を介してクラスターリソースへのアクセスを管理できます。

ユーザー代理を有効にするには:

1. `.gitlab/agents/testing/config.yaml`ファイルで、`user_access.access_as.agent: {}`を`user_access.access_as.user: {}`に置き換えます。
1. 設定されているKubernetesのダッシュボードに移動します。アクセスが制限されている場合、ダッシュボードにエラーメッセージが表示されます。
1. 以下コードを`clusters/testing/gitlab-user-read.yaml`に追加します:

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

1. 数秒間待ってFluxが追加されたマニフェストを適用できるようにしてから、もう一度Kubernetesのダッシュボードをチェックアウトします。すべてのGitLabユーザーに読み取りアクセスを付与するデプロイ済みクラスターロールバインディングのおかげで、ダッシュボードは通常の状態に戻るはずです。

ユーザーアクセスに関する詳細については、[ユーザーにKubernetesアクセスを付与](user_access.md)を参照してください。

## すべてを最新の状態に保つ {#keep-everything-up-to-date}

インストール後、Fluxおよび`agentk`をアップグレードする必要がある場合があります。

これを行うには、次の手順を実行します:

- `flux bootstrap gitlab`および`glab cluster agent bootstrap`コマンドを再実行します。

## 次の手順 {#next-steps}

エージェントを登録し、Fluxマニフェストを保存したプロジェクトからクラスターに直接デプロイできます。このエージェントはマルチテナンシーをサポートするように設計されており、設定済みのエージェントとFluxインストールで、設定を他のプロジェクトやグループにスケールすることができます。

以下のチュートリアル、[Kubernetesへのデプロイを開始する](getting_started_deployments.md)を検討してください。GitLabでKubernetesを使用する方法の詳細については、以下を参照してください:

- [GitLabインテグレーションをKubernetesで使用するためのベストプラクティス](enterprise_considerations.md)
- 運用[コンテナスキャン](vulnerabilities.md)のためのエージェントの使用
- エンジニア向けの[リモートワークスペース](../../workspace/_index.md)の提供
