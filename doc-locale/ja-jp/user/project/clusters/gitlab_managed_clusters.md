---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab管理クラスター（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.0で[GitLab Self-Managedで無効](https://gitlab.com/gitlab-org/gitlab/-/issues/353410)になりました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。クラスターをGitLabに接続するには、[Kubernetes向けGitLabエージェント](../../clusters/agent/_index.md)を使用します。アプリケーションを管理するには、[Cluster Project Management Template](../../clusters/management_project_template.md)を使用します。

{{< /alert >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。管理者が`certificate_based_clusters`という名前の[機能フラグを有効にする](../../../administration/feature_flags/_index.md)と、この機能を使用できるようになります。

{{< /alert >}}

GitLabがクラスターを管理できるように選択できます。クラスターがGitLabによって管理されている場合、プロジェクトのリソースは自動的に作成されます。作成されたリソースの詳細については、[アクセス制御](cluster_access.md)セクションを参照してください。

独自のクラスターを管理する場合、プロジェクト固有のリソースは自動的に作成されません。[Auto DevOps](../../../topics/autodevops/_index.md)を使用している場合は、使用するデプロイジョブの`KUBE_NAMESPACE`[デプロイ変数](deploy_to_cluster.md#deployment-variables)を明示的に指定する必要があります。そうでない場合は、ネームスペースが作成されます。

{{< alert type="warning" >}}

ネームスペースやサービスアカウントなど、GitLabによって作成されたリソースを手動で管理すると、予期しないエラーが発生する可能性があることに注意してください。これが発生した場合は、[クラスターのキャッシュを削除](#clearing-the-cluster-cache)してみてください。

{{< /alert >}}

## クラスターのキャッシュをクリアする {#clearing-the-cluster-cache}

GitLabにクラスターの管理を許可すると、GitLabは、プロジェクト用に作成するネームスペースとサービスアカウントのキャッシュされたバージョンを保存します。これらのリソースをクラスターで手動で変更すると、このキャッシュがクラスターと同期しなくなる可能性があります。これにより、デプロイジョブが失敗する可能性があります。

キャッシュをクリアするには:

1. プロジェクトの**操作** > **Kubernetesクラスター**ページに移動し、クラスターを選択します。
1. **Advanced settings**セクションを展開します。
1. **クラスターのキャッシュを削除**を選択します。

## ベースドメイン {#base-domain}

ベースドメインを指定すると、`KUBE_INGRESS_BASE_DOMAIN`デプロイ変数として自動的に設定されます。[Auto DevOps](../../../topics/autodevops/_index.md)を使用している場合、このドメインはさまざまなステージに使用されます。たとえば、Autoレビューアプリと自動デプロイがあります。

ドメインには、Ingress IPアドレスに設定されたワイルドカードDNSが必要です。次のいずれかの方法があります:

- ドメインプロバイダーを使用して、Ingress IPアドレスを指す`A`レコードを作成します。
- `nip.io`や`xip.io`などのサービスを使用して、ワイルドカードDNSアドレスを入力します。たとえば`192.168.1.1.xip.io`などです。

外部Ingress IPアドレスまたは外部Ingressホスト名を特定するには:

- クラスターがGKE上にある場合:
  1. **Advanced settings**の**Google Kubernetes Engine**リンクを選択するか、[Google Kubernetes Engine](https://console.cloud.google.com/kubernetes/)ダッシュボードに直接移動します。
  1. 適切なプロジェクトとクラスターを選択します。
  1. **接続**を選択します。
  1. ローカルのターミナルで、または**Cloud Shell**を使用して、`gcloud`コマンドを実行します。

- クラスターがGKE上にない場合: Kubernetesプロバイダー固有の指示に従って、適切な認証情報で`kubectl`を設定します。次の例の出力は、クラスターの外部エンドポイントを示しています。この情報は、デプロイされたアプリケーションへの外部アクセスを許可するDNSエントリと転送ルールをセットアップするために使用できます。

Ingressによっては、外部IPアドレスをさまざまな方法で取得することができます。このリストは、一般的なソリューションと、GitLab固有のアプローチをいくつか示しています:

- 一般に、次のコマンドを実行して、すべてのロードバランサーのIPアドレスをリストできます:

  ```shell
  kubectl get svc --all-namespaces -o jsonpath='{range.items[?(@.status.loadBalancer.ingress)]}{.status.loadBalancer.ingress[*].ip} '
  ```

- **アプリケーション**を使用してIngressをインストールした場合は、次を実行します:

  ```shell
  kubectl get service --namespace=gitlab-managed-apps ingress-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
  ```

- 一部のKubernetesクラスターは、[Amazon EKS](https://aws.amazon.com/eks/)のように、代わりにホスト名を返します。これらのプラットフォームの場合は、次を実行します:

  ```shell
  kubectl get service --namespace=gitlab-managed-apps ingress-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  ```

  EKSを使用する場合、[Elastic Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/)も作成されます。これにより、AWSの追加コストが発生します。

- Istio/Knativeは異なるコマンドを使用します。以下を実行します:

  ```shell
  kubectl get svc --namespace=istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip} '
  ```

一部のKubernetesバージョンで末尾に`%`が表示される場合は、含めないでください。
