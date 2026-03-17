---
stage: Deploy
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: カナリアデプロイ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

カナリアデプロイは、フリートのごく一部をアプリケーションの新しいバージョンに更新する一般的な[継続的デプロイ](https://en.wikipedia.org/wiki/Continuous_deployment)戦略です。

[継続的デリバリー](https://about.gitlab.com/blog/continuous-integration-delivery-and-deployment-with-gitlab/)を取り入れる際、組織はどのデプロイ戦略を使用するかを決定する必要があります。最も一般的な戦略の1つはカナリアデプロイで、まずフリートのごく一部が新しいバージョンに更新されます。このサブセットであるカナリアは、いわば比喩的な[炭鉱のカナリア](https://en.wiktionary.org/wiki/canary_in_a_coal_mine)として機能します。

アプリケーションの新しいバージョンに問題がある場合でも、影響を受けるユーザーはごく一部であり、変更は修正または迅速に元に戻すことができます。

## ユースケース {#use-cases}

カナリアデプロイは、ポッドフリートの一部にのみ機能をデプロイし、ユーザーベースの一部が一時的にデプロイされた機能を訪れる際の動作を監視したい場合に使用できます。すべてがうまくいけば、問題を引き起こさないことを知って、その機能を本番環境にデプロイできます。

カナリアデプロイは、バックエンドのリファクタリング、パフォーマンスの改善、またはユーザーインターフェースは変更されないが、パフォーマンスが維持または改善されることを確認したいその他の変更に対しても特に必要とされます。デベロッパーは、ユーザー向けの変更を含むカナリアを使用する際に注意が必要です。デフォルトでは、同じユーザーからのリクエストはカナリアポッドと非カナリアポッドの間でランダムに分散され、混乱やエラーにつながる可能性があるためです。必要に応じて、[お使いのKubernetesサービス定義で`service.spec.sessionAffinity`を`ClientIP`に設定する](https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies)ことを検討してもよいかもしれませんが、これはこのドキュメントのスコープ外です。

## カナリアIngressによる高度なトラフィック制御 {#advanced-traffic-control-with-canary-ingress}

カナリアデプロイは、[カナリアIngress](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#canary)を使用することでより戦略的になります。これは、ウェイト、セッション、クッキーなどの要素に基づいて、安定版とカナリア版のデプロイ間の受信HTTPリクエストを制御する高度なトラフィックルーティングサービスです。GitLabはこのサービスを[自動デプロイアーキテクチャ](../../topics/autodevops/upgrading_auto_deploy_dependencies.md#v2-chart-resource-architecture)で使用し、ユーザーが新しいデプロイを迅速かつ安全にロールアウトできるようにします。

### カナリアデプロイでカナリアIngressを設定する方法 {#how-to-set-up-a-canary-ingress-in-a-canary-deployment}

お使いのAuto DevOpsパイプラインが[`v2.0.0+`の`auto-deploy-image`](../../topics/autodevops/upgrading_auto_deploy_dependencies.md#verify-dependency-versions)を使用している場合、カナリアIngressはデフォルトでインストールされます。新しいカナリアデプロイを作成するとカナリアIngressが利用可能になり、カナリアデプロイが本番環境にプロモートされると削除されます。

以下に、最初からのセットアップフローの例を示します:

1. [Auto DevOpsが有効な](../../topics/autodevops/_index.md)プロジェクトを準備します。
1. プロジェクトで[Kubernetesクラスター](../infrastructure/clusters/_index.md)を設定します。
1. お使いのクラスターに[NGINX Ingress](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx)をインストールします。
1. 上記で割り当てられたIngressエンドポイントに基づいて、[ベースドメイン](clusters/gitlab_managed_clusters.md#base-domain)を設定します。
1. お使いのAuto DevOpsパイプラインで[`v2.0.0+`の`auto-deploy-image`](../../topics/autodevops/upgrading_auto_deploy_dependencies.md#verify-dependency-versions)が使用されているか確認します。そうでない場合は、イメージバージョンを指定するためにドキュメントに従ってください。
1. 新しい[Auto DevOpsパイプラインを実行](../../ci/pipelines/_index.md#run-a-pipeline-manually)し、`production`ジョブが成功し、本番環境が作成されることを確認します。
1. Auto DevOpsパイプライン用の[`canary`デプロイメントジョブ](../../topics/autodevops/cicd_variables.md#deploy-policy-for-canary-environments)を設定します。
1. 新しい[Auto DevOpsパイプラインを実行](../../ci/pipelines/_index.md#run-a-pipeline-manually)し、`canary`ジョブが成功し、カナリアIngressを含むカナリアデプロイが作成されることを確認します。

### カナリアIngressのデプロイをデプロイボードに表示する (非推奨) {#show-canary-ingress-deployments-on-deploy-boards-deprecated}

> [!warning]この機能はGitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

カナリアデプロイを表示するには、デプロイボードを適切に設定する必要があります:

1. [デプロイボード](deploy_boards.md#enabling-deploy-boards)を有効にする手順に従ってください。
1. カナリアデプロイを追跡するには、Kubernetesデプロイとポッドに`track: canary`というラベルを付ける必要があります。迅速に開始するには、GitLabが提供するカナリアデプロイ用の[自動デプロイ](../../topics/autodevops/stages.md#auto-deploy)テンプレートを使用できます。

デプロイに応じて、ラベルは`stable`または`canary`のいずれかである必要があります。GitLabは、ラベルが空白または欠落している場合、追跡ラベルは`stable`であると想定します。その他の追跡ラベルは`canary`（一時的）と見なされます。これにより、GitLabはデプロイが安定版かカナリア版（一時的）かを検出できます。

デプロイボードを設定し、パイプラインが少なくとも1回実行された後、**パイプライン** > **環境**の下にある環境ページに移動します。パイプラインが実行されると、デプロイボードはカナリアポッドを明確にマークし、各環境とデプロイのステータスに関する迅速かつ明確なインサイトを可能にします。

カナリアデプロイはデプロイボードで黄色の点でマークされており、すぐにそれらに気づくことができます。

![カナリアデプロイをデプロイボードで表示](img/deploy_boards_canary_deployments_v9_2.png)

#### カナリアIngressの現在のトラフィックウェイトを確認する方法 (非推奨) {#how-to-check-the-current-traffic-weight-on-a-canary-ingress-deprecated}

> [!warning]
> 
> この機能はGitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

1. [デプロイボード](deploy_boards.md)にアクセスします。
1. 右側で現在のウェイトを表示します。

   ![ロールアウトステータスカナリアIngress](img/canary_weight_v13_7.png)

#### カナリアIngressのトラフィックウェイトを変更する方法 (非推奨) {#how-to-change-the-traffic-weight-on-a-canary-ingress-deprecated}

> [!warning]
> 
> この機能はGitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

[GraphiQL](../../api/graphql/getting_started.md#graphiql)を使用するか、[GraphQL API](../../api/graphql/getting_started.md#command-line)にリクエストを送信することで、環境のデプロイボードでトラフィックウェイトを変更できます。

お使いの[デプロイボード](deploy_boards.md)を使用するには:

1. プロジェクトの**操作** > **環境**に移動します。
1. 右側のドロップダウンリストで新しいウェイトを設定します。
1. 選択内容を確認します。

[GraphiQL](../../api/graphql/getting_started.md#graphiql)を使用した例を次に示します:

1. [GraphiQL Explorer](https://gitlab.com/-/graphql-explorer)にアクセスします。
1. `environmentsCanaryIngressUpdate`GraphQLミューテーションを実行します:

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

1. リクエストが成功した場合、`errors`レスポンスは空の配列を返します。GitLabは、カナリアIngressのウェイトパラメータを更新するために、お使いのKubernetesクラスターに`PATCH`リクエストを送信します。
