---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: カナリアデプロイ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

カナリアデプロイは一般的な[継続的デプロイ](https://en.wikipedia.org/wiki/Continuous_deployment)戦略であり、フリートのごく一部がアプリケーションの新しいバージョンに更新されます。

[継続的デリバリー](https://about.gitlab.com/blog/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/)を採用する場合、組織はどのようなデプロイ戦略を使用するかを決定する必要があります。最も一般的な戦略の1つはカナリアデプロイです。この戦略では、フリートのごく一部が最初に新しいバージョンに更新されます。このサブセットであるカナリアは、ことわざにある[炭鉱のカナリア](https://en.wiktionary.org/wiki/canary_in_a_coal_mine)として機能します。

アプリケーションの新しいバージョンに問題がある場合、影響を受けるユーザーはごく一部であり、変更を修正するか、迅速に元に戻すことができます。

## ユースケース {#use-cases}

カナリアデプロイは、ポッドフリートの一部にのみ機能を実装し、ユーザーベースの割合としての一時的にデプロイされた機能へのアクセス状況を監視する場合に使用できます。すべてがうまくいけば、問題が発生しないことを認識した上で、機能を本番環境にデプロイできます。

カナリアデプロイは、バックエンドのリファクタリング、パフォーマンスの向上、またはユーザーインターフェースが変わらない他の変更で、パフォーマンスが同じか、または向上していることを確認したい場合にも特に必要です。デベロッパーは、ユーザーインターフェースに影響する変更を伴うカナリアを使用する場合は注意が必要です。デフォルトでは、同じユーザーからのリクエストはカナリアポッドと非カナリアポッドの間でランダムに分散されるため、混乱やエラーが発生する可能性があります。必要に応じて、[Kubernetesサービスの定義で`service.spec.sessionAffinity`を`ClientIP`に設定する](https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies)ことを検討してください。これはこのドキュメントのスコープ外です。

## カナリアIngressによる高度なトラフィック制御 {#advanced-traffic-control-with-canary-ingress}

カナリアデプロイは、[カナリアIngress](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#canary)を使用するとより戦略的になります。カナリアIngressは高度なトラフィックルーティングサービスで、ウェイト、セッション、Cookieなどの要素に基づいて、安定したデプロイとカナリアデプロイ間の受信HTTPリクエストを制御します。GitLabは、[自動デプロイアーキテクチャ](../../topics/autodevops/upgrading_auto_deploy_dependencies.md#v2-chart-resource-architecture)でこのサービスを使用し、ユーザーが新しいデプロイを迅速かつ安全にロールアウトできるようにします。

### カナリアデプロイでカナリアIngressを設定する方法 {#how-to-set-up-a-canary-ingress-in-a-canary-deployment}

Auto DevOpsパイプラインが[`v2.0.0+``auto-deploy-image`を使用している場合、カナリアIngressはデフォルトでインストールされます。](../../topics/autodevops/upgrading_auto_deploy_dependencies.md#verify-dependency-versions)カナリアIngressは、新しいカナリアデプロイを作成すると利用可能になり、カナリアデプロイが本番環境にプロモートされると削除されます。

これは、最初からの設定フローの例です:

1. [Auto DevOps対応](../../topics/autodevops/_index.md)プロジェクトを準備します。
1. プロジェクトに[Kubernetesクラスター](../infrastructure/clusters/_index.md)を設定します。
1. クラスターに[NGINX Ingress](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx)をインストールします。
1. 上記で割り当てられたIngressエンドポイントに基づいて、[ベースドメイン](clusters/gitlab_managed_clusters.md#base-domain)を設定します。
1. [Auto DevOpsパイプラインで`v2.0.0+``auto-deploy-image`が使用されているかどうかを確認します](../../topics/autodevops/upgrading_auto_deploy_dependencies.md#verify-dependency-versions)。そうでない場合は、ドキュメントに従ってイメージバージョンを指定します。
1. [新しいAuto DevOpsパイプラインを実行](../../ci/pipelines/_index.md#run-a-pipeline-manually)して、`production`ジョブが成功し、本番環境が作成されていることを確認します。
1. [Auto DevOpsパイプラインの`canary`デプロイメントジョブを構成](../../topics/autodevops/cicd_variables.md#deploy-policy-for-canary-environments)します。
1. [新しいAuto DevOpsパイプラインを実行](../../ci/pipelines/_index.md#run-a-pipeline-manually)して、`canary`ジョブが成功し、カナリアIngressでカナリアデプロイが作成されていることを確認します。

### デプロイボードにカナリアIngressデプロイを表示する（非推奨） {#show-canary-ingress-deployments-on-deploy-boards-deprecated}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /alert >}}

カナリアデプロイを表示するには、デプロイボードを適切に構成する必要があります:

1. [デプロイボードを有効にする](deploy_boards.md#enabling-deploy-boards)手順に従います。
1. カナリアデプロイを追跡するには、Kubernetesデプロイとポッドに`track: canary`というラベルを付ける必要があります。すぐに開始するには、GitLabが提供するカナリアデプロイ用の[自動デプロイ](../../topics/autodevops/stages.md#auto-deploy)テンプレートを使用できます。

デプロイに応じて、ラベルは`stable`または`canary`のいずれかである必要があります。GitLabは、ラベルがないか空白の場合、トラックラベルを`stable`と見なします。他のトラックラベルは、`canary`（一時的）と見なされます。これにより、GitLabはデプロイが安定しているか、カナリア（一時的）かを検出できます。

デプロイボードを構成し、パイプラインを少なくとも1回実行した後、**パイプライン** > **環境**の順にクリックして、環境ページに移動します。パイプラインの実行中に、デプロイボードはカナリアポッドを明確にマークするため、各環境とデプロイのステータスを迅速かつ明確にインサイトできます。

カナリアデプロイはデプロイボードに黄色のドットでマークされているため、すぐに気付くことができます。

![デプロイボード上のカナリアデプロイ](img/deploy_boards_canary_deployments_v9_2.png)

#### カナリアIngressの現在のトラフィックウェイトを確認する方法（非推奨） {#how-to-check-the-current-traffic-weight-on-a-canary-ingress-deprecated}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /alert >}}

1. [デプロイボード](deploy_boards.md)にアクセスします。
1. 右側の現在のウェイトを表示します。

   ![ロールアウトステータスカナリアIngress](img/canary_weight_v13_7.png)

#### カナリアIngressのトラフィックウェイトを変更する方法（非推奨） {#how-to-change-the-traffic-weight-on-a-canary-ingress-deprecated}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /alert >}}

[GraphiQL](../../api/graphql/getting_started.md#graphiql)を使用するか、[GraphQL API](../../api/graphql/getting_started.md#command-line)にリクエストを送信して、環境のデプロイボードでトラフィックウェイトを変更できます。

[デプロイボード](deploy_boards.md)を使用するには:

1. プロジェクトの**操作** > **環境**に移動します。
1. 右側のドロップダウンリストで新しいウェイトを設定します。
1. 選択を確定します。

[GraphiQL](../../api/graphql/getting_started.md#graphiql)を使用した例を次に示します:

1. [GraphiQL Explorer](https://gitlab.com/-/graphql-explorer)にアクセスします。
1. `environmentsCanaryIngressUpdate` GraphQLミューテーションを実行します:

   ```shell
   mutation {
     environmentsCanaryIngressUpdate(input:{
       id: "gid://gitlab/Environment/29",              # Your Environment ID. You can get the ID from the URL of the environment page.
       weight: 45                                      # The new traffic weight. for example, If you set `45`, 45% of traffic goes to a canary deployment and 55% of traffic goes to a stable deployment.
     }) {
       errors
     }
   }
   ```

1. リクエストが成功した場合、`errors`応答には空の配列が含まれます。GitLabは、カナリアIngressのウェイトパラメータを更新するために、`PATCH`リクエストをKubernetesクラスターに送信します。
