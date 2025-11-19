---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: クラスター証明書を介して既存のクラスターを接続します（非推奨）。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。お使いのクラスターをGitLabに接続するには、代わりに[Kubernetes向けGitLabエージェント](../../clusters/agent/_index.md)を使用してください。

{{< /alert >}}

既存のKubernetesクラスターがある場合、それをプロジェクト、グループ、またはインスタンスに追加して、GitLabとのインテグレーションのメリットを享受できます。

## 前提要件 {#prerequisites}

既存のクラスターをGitLabに追加するための前提条件を以下に示します。

### すべてのクラスター {#all-clusters}

任意のクラスターをGitLabに追加するには、以下が必要です:

- GitLab.comまたはGitLab Self-Managedインスタンスのアカウント。
- グループレベルおよびプロジェクトレベルのクラスターのメンテナーロール。
- インスタンスレベルのクラスターに対する**管理者**エリアへのアクセス。
- Kubernetesクラスター。
- `kubectl`を使用したクラスターへのクラスター管理アクセス。

[EKS](#eks-clusters) 、[GKE](#gke-clusters)、オンプレミス、およびその他のプロバイダーでクラスターをホストできます。オンプレミスおよびその他のプロバイダーでホストするには、EKSまたはGKEのいずれかの方法を使用して手順を確認し、クラスターの設定を手動で入力します。

{{< alert type="warning" >}}

GitLabは、`arm64`クラスターをサポートしていません。詳細については、[Helm Tiller fails to install on `arm64` cluster](https://gitlab.com/gitlab-org/gitlab/-/issues/29838)イシューを参照してください。

{{< /alert >}}

### EKSクラスター {#eks-clusters}

既存の**EKS**クラスターを追加するには、以下が必要です:

- 適切に構成されたワーカーノードを持つAmazon EKSクラスター。
- `kubectl`がEKSクラスターにアクセスできるように[インストールおよび構成](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#get-started-kubectl)されていること。
- アカウントのトークンに、クラスターの管理者権限があることを確認してください。

### GKEクラスター {#gke-clusters}

既存の**GKE**クラスターを追加するには、以下が必要です:

- クラスターロールバインディングを作成するための`container.clusterRoleBindings.create`権限。アクセスを許可するには、[Google Cloud documentation](https://cloud.google.com/iam/docs/granting-changing-revoking-access)に従ってください。

## 既存のクラスターを追加する方法 {#how-to-add-an-existing-cluster}

<!-- (REVISE -  BREAK INTO SMALLER STEPS) -->

Kubernetesクラスターをプロジェクト、グループ、またはインスタンスに追加するには、次の手順を実行します:

1. 以下に移動します:
   1. プロジェクトレベルのクラスターの場合は、プロジェクトの{{< icon name="cloud-gear" >}} **操作** > **Kubernetesクラスター**ページ。
   1. グループレベルのクラスターの場合は、グループの{{< icon name="cloud-gear" >}} **Kubernetes**ページ。
   1. インスタンスレベルのクラスターの場合は、**管理者**エリアの**Kubernetes**ページ。
1. **Kubernetesクラスター**ページで、**アクション**ドロップダウンリストから**Connect with a certificate**（クラスターに接続）オプションを選択します。
1. **クラスターに接続**ページで、詳細を入力します:
   1. **Kubernetesクラスター名**-クラスターに付ける名前。
   1. **環境スコープ**\- このクラスターに関連付けられた[関連環境](multiple_kubernetes_clusters.md#setting-the-environment-scope)。
   1. **API URL**\- これは、GitLabがKubernetes APIにアクセスするために使用するURIです。Kubernetesは複数のAPIを公開していますが、ここではすべてのAPIに共通する「ベース」URIが必要です。たとえば、`https://kubernetes.example.com`のように指定します（`https://kubernetes.example.com/api/v1`ではありません）。

      このコマンドを実行して、API URLを取得します:

      ```shell
      kubectl cluster-info | grep -E 'Kubernetes master|Kubernetes control plane' | awk '/http/ {print $NF}'
      ```

   1. **CA certificate**（必須）-認証するには、有効なKubernetes証明書がクラスターに必要です。ここではデフォルトで作成された証明書を使用します。
      1. `kubectl get secrets`でシークレットをリスト表示すると、`default-token-xxxxx`のような名前のシークレットが表示されます。以下の手順で使用するために、そのトークン名をコピーします。
      1. このコマンドを実行して、証明書を取得します:

         ```shell
         kubectl get secret <secret name> -o jsonpath="{['data']['ca\.crt']}" | base64 --decode
         ```

         コマンドが証明書チェーン全体を返す場合は、チェーンの下部にあるルートCA証明書とすべての中間証明書をコピーする必要があります。チェーンファイルの構造は次のとおりです:

         ```plaintext
            -----BEGIN MY CERTIFICATE-----
            -----END MY CERTIFICATE-----
            -----BEGIN INTERMEDIATE CERTIFICATE-----
            -----END INTERMEDIATE CERTIFICATE-----
            -----BEGIN INTERMEDIATE CERTIFICATE-----
            -----END INTERMEDIATE CERTIFICATE-----
            -----BEGIN ROOT CERTIFICATE-----
            -----END ROOT CERTIFICATE-----
         ```

   1. **パイプライントークン** \- GitLabは、特定の`namespace`にスコープされているサービスアカウントトークンを使用してKubernetesに対して認証します。**The token used should belong to a service account with [`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) privileges**（使用されるトークンは、 特権を持つサービスアカウントに属している必要があります）。このサービスアカウントを作成するには、次の手順を実行します:
      1. 内容が次のファイル`gitlab-admin-service-account.yaml`を作成します:

         ```yaml
         apiVersion: v1
         kind: ServiceAccount
         metadata:
           name: gitlab
           namespace: kube-system
         ---
         apiVersion: rbac.authorization.k8s.io/v1
         kind: ClusterRoleBinding
         metadata:
           name: gitlab-admin
         roleRef:
           apiGroup: rbac.authorization.k8s.io
           kind: ClusterRole
           name: cluster-admin
         subjects:
           - kind: ServiceAccount
             name: gitlab
             namespace: kube-system
         ```

      1. サービスアカウントとクラスターロールバインディングをクラスターに適用します:

         ```shell
         kubectl apply -f gitlab-admin-service-account.yaml
         ```

         クラスターレベルのロールを作成するには、`container.clusterRoleBindings.create`権限が必要です。この権限がない場合は、代わりに基本認証を有効にして、管理者として`kubectl apply`コマンドを実行します:

         ```shell
         kubectl apply -f gitlab-admin-service-account.yaml --username=admin --password=<password>
         ```

         {{< alert type="note" >}}

         基本認証を有効にして、Google Cloud Consoleを使用してパスワード認証情報を取得できます。

         {{< /alert >}}

         出力:

         ```shell
         serviceaccount "gitlab" created
         clusterrolebinding "gitlab-admin" created
         ```

      1. `gitlab`サービスアカウントのトークンを取得します:

         ```shell
         kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep gitlab | awk '{print $1}')
         ```

         `<authentication_token>`値を出力からコピーします:

         ```plaintext
         Name:         gitlab-token-b5zv4
         Namespace:    kube-system
         Labels:       <none>
         Annotations:  kubernetes.io/service-account.name=gitlab
                      kubernetes.io/service-account.uid=bcfe66ac-39be-11e8-97e8-026dce96b6e8

         Type:  kubernetes.io/service-account-token

         Data
         ====
         ca.crt:     1025 bytes
         namespace:  11 bytes
         token:      <authentication_token>
         ```

   1. **GitLab管理クラスター** \- このクラスターのネームスペースとサービスアカウントをGitLabで管理する場合は、このチェックボックスをオンのままにします。詳細については、[Managed clusters section](gitlab_managed_clusters.md)を参照してください。
   1. **Project namespace**（オプション）- これを記入する必要はありません。空白のままにすると、GitLabによって作成されます。また、次の点に注意してください:
      - 各プロジェクトには、一意のネームスペースが必要です。
      - より広範な権限を持つシークレット（`default`のシークレットなど）を使用している場合、プロジェクトのネームスペースがシークレットのネームスペースと一致するとは限りません。
      - プロジェクトのネームスペースとして`default`を**not**（使用しないでください）。
      - 自分または他の誰かがプロジェクト用に特別にシークレットを作成した場合、通常は権限が制限されており、シークレットのネームスペースとプロジェクトのネームスペースが同じになることがあります。

1. **Kubernetesクラスターを追加**ボタンを選択します。

約10分後、クラスターの準備が完了します。

## ロールベースのアクセス制御（RBAC）を無効にする（オプション） {#disable-role-based-access-control-rbac-optional}

GitLabインテグレーションを介してクラスターを接続する場合、クラスターがRBAC対応かどうかを指定できます。これは、特定の操作でGitLabがクラスターとやり取りする方法に影響します。作成時に**RBAC有効クラスター**チェックボックスをオンにしなかった場合、GitLabは、クラスターとのやり取り時にRBACが無効になっていると見なします。その場合は、インテグレーションが正しく機能するように、クラスターでRBACを無効にする必要があります。

![RBACを有効にするためのGitLab Kubernetesクラスターインテグレーション設定。](img/rbac_v13_1.png)

{{< alert type="warning" >}}

RBACを無効にすると、クラスターで実行されているアプリケーション、またはクラスターに対して認証できるユーザーは、完全なAPIアクセス権を持つことになります。これは[セキュリティ上の懸念事項](../../infrastructure/clusters/connect/_index.md#security-implications-for-clusters-connected-with-certificates)であり、望ましくない可能性があります。

{{< /alert >}}

RBACを効果的に無効にするには、グローバル権限を適用してフルアクセスを許可します:

```shell
kubectl create clusterrolebinding permissive-binding \
  --clusterrole=cluster-admin \
  --user=admin \
  --user=kubelet \
  --group=system:serviceaccounts
```

## トラブルシューティング {#troubleshooting}

### CA証明書とトークンのエラー認証時 {#ca-certificate-and-token-errors-during-authentication}

Kubernetesクラスターの接続中にこのエラーが発生した場合:

```plaintext
There was a problem authenticating with your cluster.
Please ensure your CA Certificate and Token are valid
```

サービスアカウントトークンを適切に貼り付けていることを確認してください。一部のシェルは、サービスアカウントトークンに改行を追加して、無効にする場合があります。追加のスペースを削除し、エディタにトークンを貼り付けて、改行がないことを確認します。

証明書が有効でない場合も、このエラーが発生する可能性があります。証明書のサブジェクトの別名に、クラスターのAPIの正しいドメインが含まれていることを確認するには、次のコマンドを実行します:

```shell
echo | openssl s_client -showcerts -connect kubernetes.example.com:443 -servername kubernetes.example.com 2>/dev/null |
openssl x509 -inform pem -noout -text
```

`-connect`引数は、`host:port`の組み合わせを予期します。たとえば、`https://kubernetes.example.com`は`kubernetes.example.com:443`になります。`-servername`引数は、URIを含まないドメインを予期します（例: `kubernetes.example.com`）。
