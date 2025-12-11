---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetes用エージェントをインストールする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

KubernetesクラスターをGitLabに接続するには、クラスターにエージェントをインストールする必要があります。

## 前提要件 {#prerequisites}

クラスターにエージェントをインストールする前に必要な項目は以下のとおりです:

- [ローカルターミナルから接続できる既存のKubernetesクラスター](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/)。クラスターがない場合は、以下のようなクラウドプロバイダーで作成できます:
  - [Amazon Elastic Kubernetes Service（EKS）](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
  - [Azure Kubernetes Service（AKS）](https://learn.microsoft.com/en-us/azure/aks/what-is-aks)
  - [Digital Ocean](https://docs.digitalocean.com/products/kubernetes/getting-started/quickstart/)
  - [Google Kubernetes Engine（GKE）](https://cloud.google.com/kubernetes-engine/docs/deploy-app-cluster)
  - インフラストラクチャリソースを大規模管理するには、[Infrastructure as Code](../../../infrastructure/iac/_index.md)の手法を使用する必要があります。
- エージェントサーバーへのアクセス: 
  - GitLab.comでは、エージェントサーバーは`wss://kas.gitlab.com`で利用できます。
  - GitLab Self-Managedでは、GitLab管理者が[エージェントサーバー](../../../../administration/clusters/kas.md)をセットアップする必要があります。その後、`wss://gitlab.example.com/-/kubernetes-agent/`でデフォルトで使用できます。
  - GitLab Dedicatedでは、エージェントサーバーは`wss://kas.<instance-domain>`で利用できます（例: `wss://kas.example.gitlab-dedicated.com`）。GitLab Dedicatedインスタンスに[カスタムホスト名](../../../../administration/dedicated/configure_instance/network_security.md#bring-your-own-domain-byod)を使用している場合は、KASサービスにカスタムホスト名を選択することもできます。

## Fluxサポートでエージェントをブートストラップする（推奨） {#bootstrap-the-agent-with-flux-support-recommended}

[GitLab CLI（`glab`）](../../../../editor_extensions/gitlab_cli/_index.md)とFluxでブートストラップすることにより、エージェントをインストールできます。

前提要件:

- 以下のコマンドラインツールがインストールされている必要があります:
  - `glab`
  - `kubectl`
  - `flux`
- `kubectl`および`flux`で動作するローカルクラスター接続が必要です。
- 事前に`flux bootstrap`で[Fluxをクラスターにブートストラップ](https://fluxcd.io/flux/installation/bootstrap/gitlab/)しておく必要があります。
  - 互換性のあるディレクトリにFluxとエージェントをブートストラップしてください。`--path`オプションでFluxをブートストラップした場合は、`glab cluster agent bootstrap`コマンドの`--manifest-path`オプションに同じ値を渡す必要があります。

エージェントをインストールするには、次のいずれかの方法を実行します:

- `glab cluster agent bootstrap`を対象プロジェクトのGitリポジトリのディレクトリ内で実行します: 

  ```shell
  glab cluster agent bootstrap <agent-name> --manifest-path <same_path_used_in_flux_bootstrap>
  ```

- コマンドを対象プロジェクトのGitリポジトリ外で実行する必要がある場合は、`glab -R path-with-namespace cluster agent bootstrap`を実行します: 

  ```shell
  glab -R <full/path/to/project> cluster agent bootstrap <agent-name> --manifest-path <same_path_used_in_flux_bootstrap>
  ```

デフォルトでは、コマンドは以下の動作を行います:

1. エージェントを登録します。
1. エージェントを設定します。
1. エージェントのダッシュボードで環境を設定します。
1. エージェントトークンを作成します。
1. クラスター内に、エージェントトークンでKubernetesシークレットを作成します。
1. Flux HelmリソースをGitリポジトリにコミットします。
1. Fluxの調整をトリガーします。

カスタマイズオプションについては、`glab cluster agent bootstrap --help`を実行してください。少なくとも`--path <flux_manifests_directory>`オプションを使用することをお勧めします。

## 手動でエージェントをインストールする {#install-the-agent-manually}

クラスターにエージェントをインストールするには、3つのステップが必要です:

1. オプション。[エージェント設定ファイルを作成します](#create-an-agent-configuration-file)。
1. [GitLab](#register-the-agent-with-gitlab)にエージェントを登録します。
1. [クラスターにエージェントをインストールします](#install-the-agent-in-the-cluster)。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[このプロセスのウォークスルー](https://www.youtube.com/watch?v=XuBpKtsgGkE)をご覧ください。
<!-- Video published on 2021-09-02 -->

### エージェント設定ファイルを作成する {#create-an-agent-configuration-file}

設定については、エージェントはGitLabプロジェクトのYAMLファイルを使用します。エージェント設定ファイルの追加は任意です。このファイルは、以下の場合に作成する必要があります:

- [GitLab CI/CDワークフロー](../ci_cd_workflow.md#use-gitlab-cicd-with-your-cluster)を使用していて、別のプロジェクトまたはグループにエージェントへのアクセスを承認する場合。
- [特定のプロジェクトまたはグループメンバーにKubernetesへのアクセスを許可する](../user_access.md)場合。

エージェント設定ファイルを作成するには: 

1. エージェントの名前を選択します。エージェント名は、[RFC 1123のDNSラベル標準](https://www.rfc-editor.org/rfc/rfc1123)に従います。名前は以下の条件を満たす必要があります:

   - プロジェクト内で一意である。
   - 含める文字は最大63字である。
   - 小文字の英数字または`-`のみを含む。
   - 英数字で始まる。
   - 英数字で終わる。

1. リポジトリのデフォルトブランチで、次の場所にエージェント設定ファイルを作成します:

   ```plaintext
   .gitlab/agents/<agent-name>/config.yaml
   ```

当面ファイルは空白のままにしておき、後で[設定](../work_with_agent.md#configure-your-agent)することもできます。

### GitLabにエージェントを登録する {#register-the-agent-with-gitlab}

#### オプション1: エージェントがGitLabに接続する {#option-1-agent-connects-to-gitlab}

GitLab UIから直接新しいエージェントレコードを作成できます。エージェント設定ファイルを作成せずにエージェントを登録できます。

クラスターにエージェントをインストールする前に、エージェントを登録する必要があります。エージェントを登録するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。[エージェント設定ファイル](#create-an-agent-configuration-file)がある場合、このプロジェクトに存在する必要があります。クラスターマニフェストファイルもこのプロジェクトに存在する必要があります。
1. **操作** > **Kubernetesクラスター**を選択します。
1. **クラスターに接続(エージェント)**を選択します。
1. **新しいエージェント名**フィールドに、エージェントの一意の名前を入力します。
   - この名前の[エージェント設定ファイル](#create-an-agent-configuration-file)がすでに存在する場合、その名前が使用されます。
   - この名前の設定が存在しない場合は、デフォルトの設定で新しいエージェントが作成されます。
1. **作成して登録**を選択します。
1. GitLabは、エージェントのアクセストークンを生成します。クラスターにエージェントをインストールするには、このトークンが必要です。

   {{< alert type="warning" >}}

   エージェントアクセストークンは安全な状態で保管してください。悪意のある第三者がこのトークンを使用して、エージェントの設定プロジェクトのソースコードにアクセスする、GitLabインスタンス上の任意のパブリックプロジェクトのソースコードにアクセスする、ごく特定の条件下でKubernetesマニフェストを取得するなどの可能性があります。

   {{< /alert >}}

1. **Recommended installation method**（推奨されるインストール方法）の下にあるコマンドをコピーします。これは、ワンライナーインストールメソッドを使用してクラスターにエージェントをインストールする場合に必要になります。

#### オプション2: GitLabがエージェント（受容エージェント）に接続する {#option-2-gitlab-connects-to-agent-receptive-agent}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/12180)されました。

{{< /history >}}

{{< alert type="note" >}}

GitLabエージェントHelmチャートのリリースは、mTLS認証を完全にはサポートしていません。その代わりに、JWTメソッドで認証する必要があります。mTLSのサポートは、[イシュー64](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/issues/64)で追跡されています。

{{< /alert >}}

[受容エージェント](../_index.md#receptive-agents)を使用すると、GitLabインスタンスへのネットワーク接続を確立できないがGitLabからは接続できるKubernetesクラスターと、GitLabを統合できます。

1. オプション1の手順に従って、クラスターにエージェントを登録します。エージェントトークンとインストールコマンドを後で使用するために保存します。ただし、まだエージェントはインストールしないでください。
1. 認証方法を準備します。

   GitLabからエージェントへの接続には、プレーンテキストのgRPC（`grpc://`）または暗号化されたgRPC（`grpcs://`、推奨）を使用できます。GitLabは、次の方法を使用してクラスター内のエージェントを認証できます:
   - JWTトークン。`grpc://`と`grpcs://`の両方の設定で使用できます。この方法では、クライアント証明書を生成する必要はありません。
1. [クラスターエージェントAPI](../../../../api/cluster_agents.md#create-an-agent-url-configuration)を使用して、エージェントにURL設定を追加します。URL設定を削除すると、受容エージェントは通常のエージェントになります。受容エージェントは、一度に1つのURL設定のみに関連付けることができます。

1. エージェントをクラスターにインストールします。エージェントの登録時にコピーしたコマンドを使用しますが、`--set config.kasAddress=...`パラメータは削除します。

   JWTトークン認証の例を示します。追加された`config.receptive.enabled=true`および`config.api.jwt`の設定に注意してください:

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   helm upgrade --install my-agent gitlab/gitlab-agent \
    --namespace ns \
    --create-namespace \
    --set config.token=.... \
    --set config.receptive.enabled=true \
    --set config.api.jwtPublicKey=<public_key from the response>
   ```

GitLabが新しいエージェントへの接続の確立を試行するまでに、最大10分かかる場合があります。

### エージェントをクラスターにインストールする {#install-the-agent-in-the-cluster}

クラスターをGitLabに接続するには、[Helmで登録済みのエージェントを](#install-the-agent-with-helm)インストールします。

受容エージェントをインストールするには、[GitLabがエージェント（受容エージェント）に接続する](#option-2-gitlab-connects-to-agent-receptive-agent)の手順に従います。

{{< alert type="note" >}}

複数複のクラスターに接続するには、各クラスターでエージェントを設定、登録、インストールする必要があります。各エージェントには必ず一意の名前を付けてください。

{{< /alert >}}

#### Helmでエージェントをインストールする {#install-the-agent-with-helm}

{{< alert type="warning" >}}

簡略化のため、デフォルトのHelmチャート設定では、`cluster-admin`権限を持つエージェントのサービスアカウントが設定されます。本番システムではこれを使用しないでください。本番システムにデプロイするには、[Helmインストールをカスタマイズする](#customize-the-helm-installation)の手順に従って、デプロイに必要な最小限の権限を持つサービスアカウントを作成し、インストール中に指定します。

{{< /alert >}}

Helmを使用してクラスターにエージェントをインストールするには: 

1. [Helm CLIをインストールします](https://helm.sh/docs/intro/install/)。
1. コンピューターでターミナルを開き、[クラスターに接続します](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/)。
1. [GitLabへのエージェント登録](#register-the-agent-with-gitlab)時にコピーしたコマンドを実行します。コマンドは次のようになります:

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   helm upgrade --install test gitlab/gitlab-agent \
       --namespace gitlab-agent-test \
       --create-namespace \
       --set image.tag=<current agentk version> \
       --set config.token=<your_token> \
       --set config.kasAddress=<address_to_GitLab_KAS_instance>
   ```

1. オプション。[Helmインストールをカスタマイズします](#customize-the-helm-installation)。本番環境システムにエージェントをインストールする場合は、Helmインストールをカスタマイズして、サービスアカウントの権限を制限する必要があります。以下で関連するカスタマイズオプションについて説明します。

##### Helmインストールをカスタマイズする {#customize-the-helm-installation}

デフォルトでは、GitLabによって生成されたHelmインストールコマンドになります:

- デプロイメント用のネームスペース`gitlab-agent`を作成します（`--namespace gitlab-agent`）。`--create-namespace`フラグを省略すると、ネームスペースの作成をスキップできます。
- エージェントのサービスアカウントを設定し、`cluster-admin`ロールを割り当てます。次のコマンドを実行できます:
  - `--set serviceAccount.create=false`を`helm install`コマンドに追加して、サービスアカウントの作成をスキップします。この場合、`serviceAccount.name`を既存のサービスアカウントに設定する必要があります。
  - `--set rbac.useExistingRole <your role name>`を`helm install`コマンドに追加して、サービスアカウントに割り当てられたロールをカスタマイズします。この場合、サービスアカウントで使用可能な制限付き権限を持つ、事前作成済みのロールが必要です。
  - `--set rbac.create=false`を`helm install`コマンドに追加して、ロールの割り当てをすべてスキップします。この場合、`ClusterRoleBinding`を手動で作成する必要があります。
- エージェントのアクセストークン用の`Secret`リソースを作成します。トークン付きの独自のシークレットを使用する場合は、トークン（`--set token=...`）を省略して、その代わりに`--set config.secretName=<your secret name>`を使用します。
- `agentk`ポッドの`Deployment`リソースを作成します。

利用可能なカスタマイズの完全なリストについては、Helmチャートの[README](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/blob/main/README.md#values)を参照してください。

##### KASが自己署名証明書の背後にあるときにエージェントを使用する {#use-the-agent-when-kas-is-behind-a-self-signed-certificate}

[KAS](../../../../administration/clusters/kas.md)が自己署名証明書の背後にある場合、`config.kasCaCert`の値を証明書に設定できます。例:

```shell
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --set-file config.kasCaCert=my-custom-ca.pem
```

この例では、`my-custom-ca.pem`はKASで使用されるCA証明書を含むローカルファイルへのパスになっています。証明書は、設定マップに自動的に保存され、`agentk`ポッドにマウントされます。

GitLabチャートでKASをインストールする場合、チャートが[自動生成された自己署名ワイルドカード証明書](https://docs.gitlab.com/charts/installation/tls.html#option-4-use-auto-generated-self-signed-wildcard-certificate)を提供するように設定されていると、`RELEASE-wildcard-tls-ca`シークレットからCA証明書を抽出できます。

##### HTTPプロキシの背後でエージェントを使用する {#use-the-agent-behind-an-http-proxy}

{{< history >}}

- GitLab 15.0で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/351867)GitLabエージェントHelmチャートは、環境変数の設定をサポートします。

{{< /history >}}

Helmチャートの使用時にHTTPプロキシを設定する際には、環境変数`HTTP_PROXY`、`HTTPS_PROXY`、および`NO_PROXY`を使用できます。大文字と小文字の両方を使用できます。

これらの変数は、`extraEnv`値を`name`および`value`のキーを持つオブジェクトのリストとして使用することで設定できます。たとえば、環境変数`HTTPS_PROXY`の値のみを`https://example.com/proxy`に設定するには、次のコマンドを実行します:

```shell
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --set extraEnv[0].name=HTTPS_PROXY \
  --set extraEnv[0].value=https://example.com/proxy \
  ...
```

{{< alert type="note" >}}

`HTTP_PROXY`または`HTTPS_PROXY`環境変数のいずれかが設定済みで、ドメインDNSを解決できない場合、DNSリバインディングに対する保護は無効になります。

{{< /alert >}}

## クラスターに複数のエージェントをインストールする {#install-multiple-agents-in-your-cluster}

{{< alert type="note" >}}

ほとんどの場合、クラスターごとに1つのエージェントを実行し、エージェントの代理機能（PremiumおよびUltimateのみ）を使用して、マルチテナンシーをサポートする必要があります。複数のエージェントを実行する必要があり、イシューが発生した場合は、詳細についてぜひお聞かせください。[イシュー454110](https://gitlab.com/gitlab-org/gitlab/-/issues/454110)でフィードバックを提供できます。

{{< /alert >}}

クラスターに2番目のエージェントをインストールするには、[前の手順](#register-the-agent-with-gitlab)を再度実行します。クラスター内のリソース名の衝突を回避するには、次のいずれかを実行する必要があります:

- エージェントに別のリリース名を使用します（例: `second-gitlab-agent`）:

  ```shell
  helm upgrade --install second-gitlab-agent gitlab/gitlab-agent ...
  ```

- または、エージェントを別のネームスペースにインストールします（例: `different-namespace`）:

  ```shell
  helm upgrade --install gitlab-agent gitlab/gitlab-agent \
    --namespace different-namespace \
    ...
  ```

クラスター内の各エージェントは独立して実行されるため、Fluxモジュールが有効になっているすべてのエージェントが調整をトリガーします。[イシュー357516](https://gitlab.com/gitlab-org/gitlab/-/issues/357516)では、この動作を変更することを提案しています。

次の回避策を取ることができます:

- エージェントでRBACを設定し、エージェントに必要なFluxリソースのみにアクセスするようにします。
- Fluxモジュールを使用しないエージェントのFluxモジュールを無効化します。

## プロジェクトの例 {#example-projects}

次のプロジェクトの例は、エージェントの使用を開始するのに役立ちます。

- [固有のアプリケーションおよびマニフェストリポジトリの例](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service-gitops)
- [CI/CDワークフローを使用するAuto DevOps設定](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service)
- [CI/CDワークフローを使用するクラスター管理プロジェクトテンプレートの例](https://gitlab.com/gitlab-examples/ops/gitops-demo/cluster-management)

## 更新とバージョンの互換性 {#updates-and-version-compatibility}

GitLabは、エージェントのリストページで、クラスターにインストールされているエージェントバージョンを更新するように警告します。

ベストな操作性を実現するには、クラスターにインストールされているエージェントのバージョンが、GitLabのメジャーバージョンおよびマイナーバージョンと一致する必要があります。以前のマイナーバージョンや次期のマイナーバージョンもサポートされています。たとえば、GitLabのバージョンがv14.9.4（メジャーバージョン14、マイナーバージョン9）の場合、エージェントのバージョンはv14.9.0およびv14.9.1であるのが理想的ですが、バージョンがv14.8.xまたはv14.10.xのエージェントもサポートされています。[the release page](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/releases)（GitLabエージェントfor Kubernetesのリリースページ）を参照してください。

### エージェントバージョンを更新する {#update-the-agent-version}

{{< alert type="note" >}}

`--reuse-values`を使用する代わりに、必要なすべての値を指定する必要があります。`--reuse-values`を使用すると、新しいデフォルト設定を見逃したり、非推奨の値を使用したりする可能性があります。以前の`--set`引数を取得するには、`helm get values <release name>`を使用します。`helm get values gitlab-agent > agent.yaml`を使用して値をファイルに保存し、`-f`でファイルをHelmに渡すことができます（例: `helm upgrade gitlab-agent gitlab/gitlab-agent -f agent.yaml`）。これにより、`--reuse-values`の動作が安全に置き換えられます。

{{< /alert >}}

エージェントを最新バージョンに更新するには、次のコマンドを実行します:

```shell
helm repo update
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --namespace gitlab-agent
```

特定のバージョンを設定する場合、`image.tag`値をオーバーライドできます。たとえば、バージョン`v14.9.1`をインストールする場合は、次のコマンドを実行します:

```shell
helm upgrade gitlab-agent gitlab/gitlab-agent \
  --namespace gitlab-agent \
  --set image.tag=v14.9.1
```

HelmチャートはKubernetesのエージェントとは別に更新されるため、エージェントの最新バージョンより更新が遅れる場合があります。`helm repo update`の実行時にイメージタグ付けを指定しない場合、エージェントはチャートで指定されたバージョンを実行します。

Kubernetes用エージェントの最新リリースを使用するには、イメージタグ付けを最新のエージェントイメージと一致するように設定します。

## エージェントをアンインストールする {#uninstall-the-agent}

[Helmでエージェントをインストールした](#install-the-agent-with-helm)場合、Helmでアンインストールすることもできます。たとえば、リリースとネームスペースがいずれも`gitlab-agent`という名前の場合、次のコマンドでエージェントをアンインストールできます:

```shell
helm uninstall gitlab-agent \
    --namespace gitlab-agent
```

## トラブルシューティング {#troubleshooting}

Kubernetes用エージェントのインストール時に、次のイシューが発生することがあります。

### エラー: `failed to reconcile the GitLab Agent` {#error-failed-to-reconcile-the-gitlab-agent}

`glab cluster agent bootstrap`コマンドが失敗し、`failed to reconcile the GitLab Agent`というメッセージが表示された場合、これは`glab`がFluxでエージェントを調整できなかったことを意味します。

このエラーについては次のような原因が考えられます:

- Fluxのセットアップで、`glab`がエージェント用のFluxマニフェストを配置したディレクトリを指していない。`--path`オプションでFluxをブートストラップした場合は、`glab cluster agent bootstrap`コマンドの`--manifest-path`オプションに同じ値を渡す必要があります。
- Fluxが`kustomization.yaml`のないプロジェクトのルートディレクトリを指しているため、サブディレクトリを走査してYAMLファイルを検索している。エージェントを使用するには、`.gitlab/agents/<agent-name>/config.yaml`にエージェント設定ファイルが必要ですが、これは有効なKubernetesmanifestではありません。そのためFluxはこのファイルの適用に失敗し、エラーが発生します。これを解決するには、Fluxにルートではなくサブディレクトリを指定する必要があります。
