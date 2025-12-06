---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GKEクラスターをクラスター証明書で接続する（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。[Infrastructure as Code](../../infrastructure/clusters/connect/new_gke_cluster.md)を使用して、Google Kubernetes Engine（GKE）でホストされているクラスターを作成します。

{{< /alert >}}

GitLabを使用すると、Google Kubernetes Engine（GKE）でホストされている新しいクラスターを作成し、既存のクラスターに接続できます。

## 既存のGKEクラスターを接続する {#connect-an-existing-gke-cluster}

すでにGKEクラスターがあり、それをGitLabに接続する場合は、[Kubernetes向けGitLabエージェント](../../clusters/agent/_index.md)を使用します。

## GitLabから新しいGKEクラスターを作成する {#create-a-new-gke-cluster-from-gitlab}

GitLabによってプロビジョニングされたすべてのGKEクラスターは[VPCネイティブ](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips)です。

GitLabから新しいGKEクラスターを作成するには、[Infrastructure as Code](../../infrastructure/clusters/connect/new_gke_cluster.md)を使用します。

## クラスター証明書を使用してGKEに新しいクラスターを作成する {#create-a-new-cluster-on-gke-through-cluster-certificates}

{{< history >}}

- GitLab 14.0で[非推奨](https://gitlab.com/groups/gitlab-org/-/epics/6049)になりました。

{{< /history >}}

前提要件:

- アクセス権を設定した[Google Cloud請求先アカウント](https://cloud.google.com/billing/docs/how-to/manage-billing-account)。
- Kubernetes Engine APIおよび関連サービスが有効になっています。すぐに動作するはずですが、プロジェクトの作成後、最大10分かかる場合があります。詳細については、[Kubernetes Engineドキュメントの「はじめに」セクション](https://cloud.google.com/kubernetes-engine/docs/deploy-app-cluster#before-you-begin)を参照してください。

次の点に注意してください:

- [Google AuthN（認証）インテグレーション](../../../integration/google.md)が、インスタンスレベルでGitLabで有効になっている必要があります。そうでない場合は、GitLab管理者に有効にするように依頼してください。GitLab.comでは、これは有効になっています。
- GitLabで作成されたすべてのGKEクラスターはRBAC対応です。詳細については、[RBACセクション](cluster_access.md#rbac-cluster-resources)をご覧ください。
- クラスターのポッドアドレスIP範囲は、通常の`/14`ではなく`/16`に設定されています。`/16`はCIDR表記です。
- GitLabで[初期サービスアカウント](cluster_access.md)を設定するには、基本認証を有効にし、クラスターに発行されたクライアント証明書が必要です。[GitLabバージョン11.10以降の場合、クラスター作成プロセスでは、基本認証を有効にしてクライアント証明書を使用してクラスターを作成するようにGKEに明示的にリクエストします。](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/58208)

クラスター証明書を使用して、プロジェクト、グループ、またはインスタンスに新しいKubernetesクラスターを作成するには、次のようにします:

1. 以下にアクセスします:
   - プロジェクトの{{< icon name="cloud-gear" >}} **操作** > **Kubernetesクラスター**ページ（プロジェクトレベルのクラスター）。
   - グループレベルのクラスターの場合は、グループの{{< icon name="cloud-gear" >}} **Kubernetes**ページ。
   - インスタンスレベルのクラスターの場合は、**管理者**エリアの**Kubernetes**ページ。
1. **Integrate with a cluster certificate**（クラスタ証明書とインテグレーションする）を選択します。
1. **Create new cluster**（新しいクラスターの作成）タブで、**Google GKE**を選択します。
1. **Sign in with Google**（Googleでサインイン）ボタンを選択して、まだ行っていない場合は、Googleアカウントを接続します。
1. クラスターの設定を選択します:
   - **Kubernetesクラスター名** \- クラスターに付ける名前。
   - **環境スコープ** \- このクラスターへの[関連付けられた環境](multiple_kubernetes_clusters.md#setting-the-environment-scope)。
   - **Google Cloud Platform project**（Google Cloud Platformプロジェクト） - KubernetesクラスターをホストするためにGCPコンソールで作成したプロジェクトを選択します。詳細については、[プロジェクトの作成と管理](https://cloud.google.com/resource-manager/docs/creating-managing-projects)を参照してください。
   - **ゾーン** \- クラスターを作成する[リージョンゾーン](https://cloud.google.com/compute/docs/regions-zones/)を選択します。
   - **Number of nodes**（ノード数） - クラスターに含めるノードの数を入力します。
   - **マシンタイプ** \- クラスターのベースとなる仮想マシンインスタンスの[マシンタイプ](https://cloud.google.com/compute/docs/machine-resource)。
   - **Enable Cloud Run for Anthos**（Anthos用Cloud Runを有効にする） - このクラスターにAnthos用Cloud Runを使用する場合は、これをチェックします。詳細については、[AnthosセクションのCloud Run](#cloud-run-for-anthos)を参照してください。
   - **GitLab管理クラスター** \- GitLabがこのクラスターのネームスペースとサービスアカウントを管理する場合は、このチェックを入れたままにします。詳細については、[管理対象クラスターのセクション](gitlab_managed_clusters.md)を参照してください。
1. 最後に、**Create Kubernetes cluster**（Kubernetesクラスターの作成）ボタンを選択します。

数分後、クラスターの準備が完了します。

### AnthosのCloud Run {#cloud-run-for-anthos}

クラスターの作成後、KnativeとIstioを個別にインストールする代わりに、AnthosのCloud Runを使用するように選択できます。これは、Cloud Run（Knative）、Istio、およびHTTPロードバランシングが最初からクラスターで有効になり、インストールまたはアンインストールできないことを意味します。
