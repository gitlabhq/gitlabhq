---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: デプロイボード（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.0で[GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/353410)で無効になりました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。この機能を[エージェント](../clusters/agent/_index.md)に追加するための[エピック](https://gitlab.com/groups/gitlab-org/-/epics/2493)が存在します。

{{< /alert >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。管理者が`certificate_based_clusters`という名前の[機能フラグを有効にする](../../administration/feature_flags/_index.md)と、この機能を使用できるようになります。

{{< /alert >}}

GitLabデプロイボードは、[Kubernetes](https://kubernetes.io)上で実行されている各CI[環境](../../ci/environments/_index.md)の現在の正常性とステータスをまとめて表示し、デプロイメント内のポッドのステータスを表示します。デベロッパーや他のチームメイトは、Kubernetesにアクセスしなくても、すでに使用しているワークフローで、ロールアウトの進捗とステータスをポッドごとに確認できます。

{{< alert type="note" >}}

Kubernetesクラスターがある場合は、[Auto DevOps](../../topics/autodevops/_index.md)を使用して、アプリケーションを本番環境に自動デプロイできます。

{{< /alert >}}

デプロイボードを使用すると、次のような利点により、デプロイに関するインサイトをより深く得ることができます:

- 最初からデプロイを追跡できる（完了時だけでなく）
- 複数のサーバーにわたるビルドのロールアウトを監視できる
- より詳細な状態（成功、実行中、失敗、保留中、不明）
- [カナリアデプロイ](canary_deployments.md)を参照してください。

これは本番環境のデプロイボードの例です。

![Kubernetesクラスターポッドを使用した本番環境のデプロイメントを示すダッシュボード。](img/deploy_boards_landing_page_v9_0.png)

正方形は、指定された環境に関連付けられているKubernetesクラスター内のポッドを表しています。各正方形の上にマウスを置くと、デプロイのロールアウトの状態を確認できます。パーセンテージは、最新のリリースに更新されたポッドの割合です。

デプロイボードはKubernetesと密接に結合しているため、以下について理解しておく必要があります:

- [Kubernetesのポッド](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Kubernetesラベル](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- [Kubernetesのネームスペース](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Kubernetesカナリアデプロイメント](https://kubernetes.io/docs/concepts/workloads/management/#canary-deployments)

## ユースケース {#use-cases}

デプロイボードは、特定の環境のKubernetesポッドを視覚的に表現したものであるため、多くのユースケースがあります。いくつか例を挙げます:

- ステージングで実行されているものを本番にプロモートしたいとします。そこで、環境リストに移動し、ステージングで実行されているものが想定どおりであることを確認し、本番にデプロイするための[手動ジョブ](../../ci/jobs/job_control.md#create-a-job-that-must-be-run-manually)を選択します。
- デプロイをトリガーし、アップグレードするコンテナが多数あるため、時間がかかることがわかっています（一度にX個のコンテナしかダウンさせないように、デプロイを調整しました）。しかし、デプロイされたときに誰かに伝える必要があるので、環境リストに移動し、本番環境を見て、各ポッドがロールアウトされるにつれて、進捗状況がリアルタイムでどうなっているかを確認します。
- 本番で何かおかしいというレポートを受け取ったので、本番環境を見て、何が実行されているか、そしてデプロイが進行中か、停止しているか、または失敗したかを確認します。
- 見栄えの良いマージリクエストがありますが、ステージングが本番に近い方法でセットアップされているため、ステージングで実行したいと考えています。そこで、環境リストに移動し、関心のある[レビューアプリ](../../ci/review_apps/_index.md)を見つけて、それをステージングにデプロイするための手動アクションを選択します。

## デプロイボードの有効化 {#enabling-deploy-boards}

特定の[environment](../../ci/environments/_index.md)のデプロイボードを表示するには、次のようにします:

1. デプロイステージで[定義された環境](../../ci/environments/_index.md)が必要です。

1. Kubernetesクラスターが起動して実行されている必要があります。

   {{< alert type="note" >}}

   OpenShiftを使用している場合は、`Deployment`ではなく`DeploymentConfiguration`リソースを使用していることを確認してください。そうしないと、デプロイボードが正しくレンダリングされません。詳細については、[OpenShiftドキュメント](https://docs.openshift.com/container-platform/3.7/dev_guide/deployments/kubernetes_deployments.html#kubernetes-deployments-vs-deployment-configurations)と[GitLabイシュー＃4584](https://gitlab.com/gitlab-org/gitlab/-/issues/4584)を参照してください。

   {{< /alert >}}

1. [`docker`](https://docs.gitlab.com/runner/executors/docker.html)または[`kubernetes`](https://docs.gitlab.com/runner/executors/kubernetes/) executorで[GitLab Runner](../../ci/runners/_index.md)を構成します。
1. クラスターのプロジェクトで[Kubernetesインテグレーション](../infrastructure/clusters/_index.md)を構成します。Kubernetesネームスペースは、`KUBE_NAMESPACE`CI/CD変数によって公開されるデプロイスクリプトに必要となるため、特に注意が必要です。
1. `app.gitlab.com/env: $CI_ENVIRONMENT_SLUG`および`app.gitlab.com/app: $CI_PROJECT_PATH_SLUG`のKubernetes注釈がデプロイメント、レプリカセット、およびポッドに適用されていることを確認してください。ここで、`$CI_ENVIRONMENT_SLUG`と`$CI_PROJECT_PATH_SLUG`はCI/CD変数の値です。これは、複数のクラスター / ネームスペースにある可能性のある適切な環境をルックアップできるようにするためです。これらのリソースは、Kubernetesサービスの設定で定義されたネームスペースに含まれている必要があります。定義済みのステージと使用するコマンドがあり、注釈を自動的に適用する[自動デプロイ](../../topics/autodevops/stages.md#auto-deploy) `.gitlab-ci.yml`テンプレートを使用できます。各プロジェクトには、Kubernetesに一意のネームスペースも必要です。下の図は、これがKubernetes内でどのように表示されるかを示しています。

   GCPを使用してクラスターを管理している場合は、**Workloads**（ワークロード） > **deployment name**（デプロイ名） > **詳細**に移動して、GCP自体でデプロイの詳細を確認できます:

   ![GCPデプロイボードの詳細。](img/deploy_boards_kubernetes_label_v11_9.png)

これまでのすべての手順をセットアップし、パイプラインを少なくとも1回実行したら、**操作** > **環境**の下の環境ページに移動します。

デプロイボードはデフォルトで表示されます。それぞれの環境名の横にある三角形を明示的に選択して、非表示にすることができます。

### マニフェストファイルの例 {#example-manifest-file}

次の例は、2つの注釈`app.gitlab.com/env`と`app.gitlab.com/app`を使用して**deploy boards**（デプロイボード）を有効にするKubernetesマニフェストデプロイメントファイルからの抜粋です:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "APPLICATION_NAME"
  annotations:
    app.gitlab.com/app: ${CI_PROJECT_PATH_SLUG}
    app.gitlab.com/env: ${CI_ENVIRONMENT_SLUG}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: "APPLICATION_NAME"
  template:
    metadata:
      labels:
        app: "APPLICATION_NAME"
      annotations:
        app.gitlab.com/app: ${CI_PROJECT_PATH_SLUG}
        app.gitlab.com/env: ${CI_ENVIRONMENT_SLUG}
```

これらの注釈は、デプロイメント、レプリカセット、およびポッドに適用されます。`kubectl scale --replicas=3 deploy APPLICATION_NAME -n ${KUBE_NAMESPACE}`のように、レプリカの数を変更することで、ボードからインスタンスのポッドを追跡できます。

{{< alert type="note" >}}

YAMLファイルは静的です。`kubectl apply`を使用して適用する場合は、プロジェクトと環境のslugを手動で指定するか、適用する前にYAMLの変数を置き換えるスクリプトを作成する必要があります。

{{< /alert >}}

## カナリアデプロイ {#canary-deployments}

一般的なCI戦略。フリートのほんの一部が、アプリケーションの新しいバージョンに更新されます。

[カナリアデプロイメントの詳細をご覧ください。](canary_deployments.md)

## さらに詳しく {#further-reading}

- [GitLab自動デプロイ](../../topics/autodevops/stages.md#auto-deploy)
- [GitLab CI/CD変数](../../ci/variables/_index.md)
- [環境とデプロイ](../../ci/environments/_index.md)
- [Kubernetesデプロイの例](https://gitlab.com/gitlab-examples/kubernetes-deploy)
