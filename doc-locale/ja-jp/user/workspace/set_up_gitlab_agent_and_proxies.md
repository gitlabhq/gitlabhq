---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabワークスペースの認証と認可を行うために、GitLabワークスペースプロキシをクラスター内に作成します。
title: 'チュートリアル: Kubernetes向けGitLabエージェントをセットアップする'
---

<!-- vale gitlab_base.FutureTense = NO -->

このチュートリアルでは、次の方法を説明します:

- [Kubernetes向けGitLabエージェント](../clusters/agent/_index.md)を設定し、ユーザーがプロジェクトでワークスペースを作成管理できるようにします。
- GitLabワークスペースプロキシを設定して、クラスター内の[ワークスペース](_index.md)の認証と認可を行います。

> [!note]
> ワークスペースをサポートするようにKubernetes向けGitLabエージェントを設定する前に、このチュートリアルで設定手順を完了する必要があります。チュートリアルを完了したら、[Kubernetes向けGitLabエージェントの設定](gitlab_agent_configuration.md)を使用してエージェントを設定します。

## はじめる前 {#before-you-begin}

このチュートリアルを開始する前に、以下が必要です:

- GitLabインスタンスへの管理者アクセス権、またはグループのオーナーロール。
- 稼働中のKubernetesクラスター。
- `helm` 3.11.0以降と、ローカルマシン上の`kubectl`。
- DNSプロバイダーでワイルドカードドメインを設定するアクセス権。例えば、`*.workspaces.example.dev`はワークスペースアクセスに必要です。

このチュートリアルでは、次の階層を使用します:

```mermaid
%%{init: {  "fontFamily": "GitLab Sans" }}%%
graph TD
    accTitle: Hierarchy structure for GitLab workspaces
    accDescr: Workspace projects inherit agent access through the group hierarchy with agents connected to separate agent projects.

    topGroup[Top-level group]
    subGroup[Subgroup]
    workspaceProject[Workspace project]
    agentProject[Agent project]
    workspaceAgent[Workspace agent]

    topGroup --> subGroup

    subGroup --> workspaceProject
    subGroup --> agentProject
    agentProject -.- workspaceAgent

    class workspaceProject active;
```

## Ingressコントローラーをインストールする {#install-an-ingress-controller}

Kubernetesクラスターに任意の[Ingressコントローラー](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)をインストールして、外部トラフィックをワークスペースにルーティングします。IngressコントローラーはWebSocketsをサポートしている必要があります。次の例では、[Ingress NGINXコントローラー](https://github.com/kubernetes/ingress-nginx)を使用します。

1. KubernetesクラスターにIngressコントローラーをインストールします。

   ```shell
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo update
   helm install ingress-nginx ingress-nginx/ingress-nginx \
     --namespace gitlab-ingress-controller \
     --create-namespace
   ```

1. ロードバランサーの外部IPアドレスを取得します。[DNSレコード](#update-your-dns-records)を更新する際にこれが必要になります。

   ```shell
   kubectl get svc -n gitlab-ingress-controller ingress-nginx-controller
   ```

## Kubernetes向けGitLabエージェントをインストールする {#install-the-gitlab-agent-for-kubernetes}

[Kubernetes向けGitLabエージェント](../clusters/agent/_index.md#kubernetes-integration-glossary)をKubernetesクラスターにインストールして、クラスターをGitLabに接続します:

1. [Kubernetes向けエージェントのインストール](../clusters/agent/install/_index.md)のいずれかのインストールオプションを完了してください。
1. 設定した`agentName`をメモします。ワークスペース用にエージェントを設定する際に必要です。

## GitLab Relay (KAS) をインストールします {#install-gitlab-relay-kas}

GitLab Relay (KAS) は、クラスター内のエージェントと通信するコンポーネントです。

- GitLab.comでは、GitLab Relay (KAS) はデフォルトで`wss://kas.gitlab.com`で利用できます。
- GitLab Self-Managedでは、管理者が[GitLab Relay (KAS) を設定](../../administration/clusters/kas.md)する必要があります。その後、`wss://gitlab.example.com/-/kubernetes-agent/`で利用可能です。

## Kubernetes向けGitLabエージェントを設定する {#configure-the-gitlab-agent-for-kubernetes}

エージェントプロジェクトで`remote_development`モジュールを設定するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. プロジェクトで`.gitlab/agents/<agentName>/config.yaml`ファイルを作成します。`agentName`は、ワークスペースインフラストラクチャを設定した際に設定したエージェントの名前です。
1. `config.yaml`で、ワークスペースの設定に次の設定を使用します:

   ```yaml
   remote_development:
     enabled: true
     dns_zone: "<workspaces.example.dev>" # DNS zone of the URL where workspaces are available
   ```

設定オプションの全リストについては、ワークスペースの[設定参照](settings.md#configuration-reference)を参照してください。

> [!note]
> Kubernetes向けGitLabエージェントは1つのプロジェクトで設定されますが、他のプロジェクトワークスペースで使用できます。各プロジェクトに個別のエージェントは必要ありません。
>
> 設定済みのエージェントは、グループで[グループでエージェントを許可](#allow-the-gitlab-agent-for-kubernetes-in-your-group)するまで表示されません。

## グループでKubernetes向けGitLabエージェントを許可する {#allow-the-gitlab-agent-for-kubernetes-in-your-group}

グループでエージェントを許可すると、そのグループ、サブグループ、およびそれらのグループ内のすべてのプロジェクトでそのエージェントを使用できます。

> [!note]
> 必要なエージェントは1つだけです。同じエージェントを使用するグループ内のすべてのプロジェクトからワークスペースを作成できます。

グループでKubernetes向けGitLabエージェントを許可し、そのグループ内のすべてのプロジェクトで利用できるようにするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**設定** > **ワークスペース**を選択します。
1. **グループエージェント**セクションで、**すべてのエージェント**タブを選択します。
1. Kubernetes向けGitLabエージェントで、**許可**を選択します。
1. 確認ダイアログで、**エージェントを許可する**を選択します。

## ワークスペース権限を付与する {#grant-workspace-permissions}

ワークスペースおよびエージェントプロジェクトのデベロッパー、メンテナー、またはオーナーロールを持つユーザーに、ワークスペースを作成および管理するために必要な権限を付与します。次のことができます: 

- [プロジェクトにユーザーを追加する](../project/members/_index.md#add-users-to-a-project)
- [グループにユーザーを追加する](../group/_index.md#add-users-to-a-group)

## TLS証明書を生成する {#generate-tls-certificates}

各ワークスペースは独自のサブドメインを取得するため、ワークスペースアクセスにはワイルドカードドメインが必要です。以下についてTLS証明書を生成する必要があります:

- `gitlab-workspaces-proxy`がリッスンするドメイン (`GITLAB_WORKSPACES_PROXY_DOMAIN`)。
- ワークスペースが利用可能なワイルドカードドメイン (`GITLAB_WORKSPACES_WILDCARD_DOMAIN`)。

例えば、ベースドメインが`workspaces.example.dev`の場合:

- `GITLAB_WORKSPACES_PROXY_DOMAIN`は`workspaces.example.dev`です。
- `GITLAB_WORKSPACES_WILDCARD_DOMAIN`は`*.workspaces.example.dev`です。
- 個々のワークスペースは、`workspace-1.workspaces.example.dev`のようなURLで利用できます。

任意の認証局から証明書を生成できます。Kubernetesクラスター用に[`cert-manager`](https://cert-manager.io/docs/)が設定されている場合は、それを使用してTLS証明書を自動的に作成および更新できます。

手動で証明書を生成するには:

1. HTTPSを有効にするには、[Certbot](https://certbot.eff.org/)をインストールします:

   ```shell
   brew install certbot
   ```

1. Let's Encrypt証明書をACME DNSで生成し、DNSプロバイダーに`TXT`レコードを作成します:

   ```shell
   export EMAIL="YOUR_EMAIL@example.dev"
   export GITLAB_WORKSPACES_PROXY_DOMAIN="workspaces.example.dev"
   export GITLAB_WORKSPACES_WILDCARD_DOMAIN="*.workspaces.example.dev"

   certbot -d "${GITLAB_WORKSPACES_PROXY_DOMAIN}" \
     -m "${EMAIL}" \
     --config-dir ~/.certbot/config \
     --logs-dir ~/.certbot/logs \
     --work-dir ~/.certbot/work \
     --manual \
     --preferred-challenges dns certonly

   certbot -d "${GITLAB_WORKSPACES_WILDCARD_DOMAIN}" \
     -m "${EMAIL}" \
     --config-dir ~/.certbot/config \
     --logs-dir ~/.certbot/logs \
     --work-dir ~/.certbot/work \
     --manual \
     --preferred-challenges dns certonly
   ```

1. 出力からの証明書ディレクトリで、次の環境変数を設定します:

   ```shell
   export WORKSPACES_DOMAIN_CERT="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_PROXY_DOMAIN}/fullchain.pem"
   export WORKSPACES_DOMAIN_KEY="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_PROXY_DOMAIN}/privkey.pem"
   export WILDCARD_DOMAIN_CERT="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_PROXY_DOMAIN}-0001/fullchain.pem"
   export WILDCARD_DOMAIN_KEY="${HOME}/.certbot/config/live/${GITLAB_WORKSPACES_PROXY_DOMAIN}-0001/privkey.pem"
   ```

   環境によっては、`certbot`コマンドが証明書とキーを別のパスに保存する場合があります。正確なパスを取得するには、以下を実行します:

   ```shell
   certbot certificates \
     --config-dir ~/.certbot/config \
     --logs-dir ~/.certbot/logs \
     --work-dir ~/.certbot/work
   ```

> [!note]
> 証明書の有効期限が切れたら、更新する必要があります。例えば、Let's Encrypt証明書は3ヶ月後に有効期限が切れます。証明書を自動的に更新するには、[`cert-manager`](https://cert-manager.io/docs/)を参照してください。

## GitLab OAuthアプリケーションを登録する {#register-a-gitlab-oauth-application}

GitLabインスタンスでOAuthアプリケーションを登録するには:

1. GitLabで[OAuthアプリケーションを作成](../../integration/oauth_provider.md)します。次のいずれかを作成できます:
   - ユーザー所有のアプリケーション
   - グループ所有のアプリケーション
   - 管理者エリアからインスタンス全体のアプリケーション
1. リダイレクトURIを`https://${GITLAB_WORKSPACES_PROXY_DOMAIN}/auth/callback`に設定します。
1. **非公開**チェックボックスが選択されていることを確認します。デフォルトで選択されているはずです。
1. インスタンス全体のアプリケーションを作成する場合は、**信用済み**チェックボックスも選択します。
1. スコープを`api`, `read_user`, `openid`, および`profile`に設定します。
1. 設定値をエクスポートします:

   ```shell
   export GITLAB_URL="https://gitlab.com"
   export CLIENT_ID="your_application_id"
   export CLIENT_SECRET="your_application_secret"
   export REDIRECT_URI="https://${GITLAB_WORKSPACES_PROXY_DOMAIN}/auth/callback"
   export SIGNING_KEY="make_up_a_random_key_consisting_of_letters_numbers_and_special_chars"
   ```

1. クライアントIDと生成されたシークレットを、例えば1Passwordなどに安全に保存します。

## SSHホストキーを生成する {#generate-an-ssh-host-key}

RSAキーを生成するには:

```shell
ssh-keygen -f ssh-host-key -N '' -t rsa
export SSH_HOST_KEY=$(pwd)/ssh-host-key
```

代わりに、ECDSAキーを生成することもできます。

## Kubernetes Secretsを作成する {#create-kubernetes-secrets}

Kubernetes Secretsを作成するには:

```shell
kubectl create namespace gitlab-workspaces

kubectl create secret generic gitlab-workspaces-proxy-config \
  --namespace="gitlab-workspaces" \
  --from-literal="auth.client_id=${CLIENT_ID}" \
  --from-literal="auth.client_secret=${CLIENT_SECRET}" \
  --from-literal="auth.host=${GITLAB_URL}" \
  --from-literal="auth.redirect_uri=${REDIRECT_URI}" \
  --from-literal="auth.signing_key=${SIGNING_KEY}" \
  --from-literal="ssh.host_key=$(cat ${SSH_HOST_KEY})"

kubectl create secret tls gitlab-workspace-proxy-tls \
  --namespace="gitlab-workspaces" \
  --cert="${WORKSPACES_DOMAIN_CERT}" \
  --key="${WORKSPACES_DOMAIN_KEY}"

kubectl create secret tls gitlab-workspace-proxy-wildcard-tls \
  --namespace="gitlab-workspaces" \
  --cert="${WILDCARD_DOMAIN_CERT}" \
  --key="${WILDCARD_DOMAIN_KEY}"
```

## GitLabワークスペースプロキシHelmチャートをインストールする {#install-the-gitlab-workspaces-proxy-helm-chart}

GitLabワークスペースプロキシのHelmチャートをインストールするには:

1. `helm`リポジトリを追加します:

   ```shell
   helm repo add gitlab-workspaces-proxy \
     https://gitlab.com/api/v4/projects/gitlab-org%2fworkspaces%2fgitlab-workspaces-proxy/packages/helm/devel
   ```

   Helmチャート0.1.13以前の場合は、次のコマンドを使用します:

   ```shell
   helm repo add gitlab-workspaces-proxy \
     https://gitlab.com/api/v4/projects/gitlab-org%2fremote-development%2fgitlab-workspaces-proxy/packages/helm/devel
   ```

1. チャートをインストールしてアップグレードします:

   > [!warning]
   > チャートバージョン0.1.22以前には、コマンドライン引数を介して機密情報を公開するセキュリティ脆弱性が含まれています。詳細については、[脆弱性](https://gitlab.com/gitlab-org/gitlab/-/issues/567267)を参照してください。
   >
   > チャートバージョン0.1.20以前にも、ワイルドカードドメインにCookieを設定するセキュリティ脆弱性が含まれています。詳細については、[脆弱性の修正](https://gitlab.com/gitlab-org/workspaces/gitlab-workspaces-proxy/-/merge_requests/34)を参照してください。
   >
   > 両方の脆弱性に対処するには、チャートバージョン0.1.23以降にアップグレードする必要があります。
   >
   > チャートバージョン0.1.16以前では、Helmチャートのインストール時にシークレットが自動的に作成されていました。バージョン0.1.16以前からアップグレードする場合は、アップグレードコマンドを実行する前に[必要なKubernetes Secretsを作成](#create-kubernetes-secrets)してください。

   ```shell
   helm repo update

   helm upgrade --install gitlab-workspaces-proxy \
     gitlab-workspaces-proxy/gitlab-workspaces-proxy \
     --version=0.1.25 \
     --namespace="gitlab-workspaces" \
     --set="ingress.enabled=true" \
     --set="ingress.hosts[0].host=${GITLAB_WORKSPACES_PROXY_DOMAIN}" \
     --set="ingress.hosts[0].paths[0].path=/" \
     --set="ingress.hosts[0].paths[0].pathType=ImplementationSpecific" \
     --set="ingress.hosts[1].host=${GITLAB_WORKSPACES_WILDCARD_DOMAIN}" \
     --set="ingress.hosts[1].paths[0].path=/" \
     --set="ingress.hosts[1].paths[0].pathType=ImplementationSpecific" \
     --set="ingress.tls[0].hosts[0]=${GITLAB_WORKSPACES_PROXY_DOMAIN}" \
     --set="ingress.tls[0].secretName=gitlab-workspace-proxy-tls" \
     --set="ingress.tls[1].hosts[0]=${GITLAB_WORKSPACES_WILDCARD_DOMAIN}" \
     --set="ingress.tls[1].secretName=gitlab-workspace-proxy-wildcard-tls" \
     --set="ingress.className=nginx"
   ```

   別のIngressクラスを使用している場合は、`ingress.className`パラメータを変更します。

## 設定を確認する {#verify-your-setup}

1. `gitlab-workspaces`ネームスペースのIngress設定を確認します:

   ```shell
   kubectl -n gitlab-workspaces get ingress
   ```

1. ポッドが実行中であることを確認します:

   ```shell
   kubectl -n gitlab-workspaces get pods
   ```

## DNSレコードを更新する {#update-your-dns-records}

DNSレコードを更新するには:

1. `${GITLAB_WORKSPACES_PROXY_DOMAIN}`と`${GITLAB_WORKSPACES_WILDCARD_DOMAIN}`を、[Ingressコントローラー](#install-an-ingress-controller)によって公開されたロードバランサーの外部IPアドレスに向けます。
1. `gitlab-workspaces-proxy`がアクセス可能であることを確認します:

   ```shell
   curl --verbose --location ${GITLAB_WORKSPACES_PROXY_DOMAIN}
   ```

   このコマンドは、ワークスペースを作成するまで`400 Bad Request`エラーを返します。

1. 別のターミナルからプロキシログを確認します:

   ```shell
   kubectl -n gitlab-workspaces logs -f -l app.kubernetes.io/name=gitlab-workspaces-proxy
   ```

   このコマンドは、ワークスペースを作成するまで`could not find upstream workspace upstream not found`エラーを返します。

## Kubernetes向けGitLabエージェントの設定を更新する {#update-the-gitlab-agent-for-kubernetes-configuration}

プロキシのHelmチャートを`gitlab-workspaces`以外のネームスペースにデプロイする場合は、[Kubernetes向けGitLabエージェントの設定](gitlab_agent_configuration.md)を更新します:

```yaml
remote_development:
  gitlab_workspaces_proxy:
    namespace: "<custom-gitlab-workspaces-proxy-namespace>"
```

## 関連トピック {#related-topics}

- [ワークスペースを設定する](configuration.md)
- [Kubernetes向けGitLabエージェントの設定](gitlab_agent_configuration.md)
