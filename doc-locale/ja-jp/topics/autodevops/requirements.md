---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Auto DevOpsの要件
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Auto DevOps](_index.md)を有効にする前に、デプロイの準備を整えておくことをおすすめします。準備をしなくても、まずAuto DevOpsを使用してアプリのビルドとテストを行い、後でデプロイを設定することは可能です。

デプロイを準備するには、次の手順に従います。

1. [デプロイ戦略](#auto-devops-deployment-strategy)を定義します。
1. [ベースドメイン](#auto-devops-base-domain)を準備します。
1. デプロイ先を定義します。

   1. [Kubernetes](#auto-devops-requirements-for-kubernetes)。
   1. [Amazon Elastic Container Service（Amazon ECS）](cloud_deployments/auto_devops_with_ecs.md)。
   1. [Amazon Elastic Kubernetes Service（Amazon EKS）](https://about.gitlab.com/blog/2020/05/05/deploying-application-eks/)。
   1. [Amazon Elastic Compute Cloud（Amazon EC2）](cloud_deployments/auto_devops_with_ec2.md)。
   1. [Google Kubernetes Engine](cloud_deployments/auto_devops_with_gke.md)。
   1. [ベアメタル](#auto-devops-requirements-for-bare-metal)。

1. [Auto DevOps](_index.md#enable-or-disable-auto-devops)を有効にします。

## Auto DevOpsのデプロイ戦略 {#auto-devops-deployment-strategy}

Auto DevOpsを使用してアプリケーションをデプロイする場合は、ニーズに最適な[継続的デプロイ戦略](../../ci/_index.md)を選択してください。

| デプロイ戦略                                                     | セットアップ | 開発手法 |
|-------------------------------------------------------------------------|-------|-------------|
| **本番環境への継続的デプロイ**                                 | デフォルトブランチを本番環境に継続的にデプロイするための[Auto Deploy](stages.md#auto-deploy)を有効にします。 | 本番環境への継続的デプロイ。|
| **スケジュールされた増分ロールアウトを用いた本番環境への継続的デプロイ** | [`INCREMENTAL_ROLLOUT_MODE`](cicd_variables.md#timed-incremental-rollout-to-production)変数を`timed`に設定します。 | ロールアウト間に5分の遅延を設けて、本番環境に継続的にデプロイします。 |
| **ステージングへの自動デプロイ、本番環境への手動デプロイ**    | [`STAGING_ENABLED`](cicd_variables.md#deploy-policy-for-staging-and-production-environments)を`1`に、[`INCREMENTAL_ROLLOUT_MODE`](cicd_variables.md#incremental-rollout-to-production)を`manual`に設定します。 | デフォルトブランチを継続的にステージングにデプロイし、本番環境には継続的デリバリーを行います。 |

デプロイ方法は、Auto DevOpsを有効にする際、または後から選択できます。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Auto DevOps**を展開します。
1. デプロイ戦略を選択します。
1. **変更を保存**を選択します。

{{< alert type="note" >}}

ダウンタイムとリスクを最小限に抑えるため、[ブルー/グリーンデプロイ](../../ci/environments/incremental_rollouts.md#blue-green-deployment)手法を使用してください。

{{< /alert >}}

## Auto DevOpsのベースドメイン {#auto-devops-base-domain}

[Auto Review Apps](stages.md#auto-review-apps)と[Auto Deploy](stages.md#auto-deploy)を使用するには、Auto DevOpsのベースドメインが必要です。

ベースドメインを定義するには、次のいずれかを実行します。

- プロジェクト、グループ、またはインスタンスレベル: クラスター設定に移動し、そこで追加します。
- プロジェクトまたはグループレベル: 環境変数として追加します: `KUBE_INGRESS_BASE_DOMAIN`。
- インスタンスレベル: **管理者**エリアに移動し、**設定 > CI/CD > 継続的インテグレーションとデリバリー**に移動して、そこで追加します。

ベースドメイン変数`KUBE_INGRESS_BASE_DOMAIN`は、[他の環境変数と同じ優先順位](../../ci/variables/_index.md#cicd-variable-precedence)に従います。

プロジェクトとグループでベースドメインを指定しない場合、Auto DevOpsはインスタンス全体の**Auto DevOpsドメイン**を使用します。

Auto DevOpsには、ベースドメインに一致するワイルドカードDNS `A`レコードが必要です。ベースドメインが`example.com`の場合、次のようなDNSエントリが必要です。

```plaintext
*.example.com   3600     A     10.0.2.2
```

この場合、デプロイされたアプリケーションは`example.com`から提供され、`10.0.2.2`はロードバランサー（一般的にはNGINX）のIPアドレスです（[要件を参照](requirements.md)）。DNSレコードのセットアップは、このドキュメントの範囲外です。詳細については、DNSプロバイダーにお問い合わせください。

または、設定なしで自動ワイルドカードDNSを提供する無料のパブリックサービス（[nip.io](https://nip.io)など）を使用することもできます。[nip.io](https://nip.io)の場合、Auto DevOpsのベースドメインを`10.0.2.2.nip.io`に設定します。

セットアップが完了すると、すべてのリクエストはロードバランサーに到達し、ロードバランサーはアプリケーションを実行しているKubernetesポッドにリクエストをルーティングします。

## KubernetesのAuto DevOps要件 {#auto-devops-requirements-for-kubernetes}

KubernetesでAuto DevOpsを最大限に活用するには、以下が必要です。

- **Kubernetes**（[Auto Review Apps](stages.md#auto-review-apps)および[Auto Deploy](stages.md#auto-deploy)用）

  デプロイを有効にするには、以下が必要です。

  1. プロジェクト用の[Kubernetes 1.12以降のクラスター](../../user/infrastructure/clusters/_index.md)。Kubernetes 1.16以降のクラスターの場合、[Kubernetes 1.16以降用のAuto Deploy](stages.md#kubernetes-116)を使用するために追加の設定が必要です。
  1. 外部HTTPトラフィック用のIngressコントローラー。通常のデプロイではどのIngressコントローラーでも動作するはずですが、GitLab 14.0以降、[カナリアデプロイ](../../user/project/canary_deployments.md)にはNGINX Ingressが必要です。GitLab[クラスター管理プロジェクトテンプレート](../../user/clusters/management_project_template.md)を使用するか、[`ingress-nginx`](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx) Helmチャートを使用して、手動でNGINX IngressコントローラーをKubernetesクラスターにデプロイできます。

     [カスタムチャートを使用](customize.md#custom-helm-chart)してデプロイする場合は、`prometheus.io/scrape: "true"`および`prometheus.io/port: "10254"`を[アノテーション](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)としてIngressマニフェストに追加し、Prometheusによるスクレイプを有効にする必要があります。

     {{< alert type="note" >}}

     クラスターがベアメタルにインストールされている場合は、[ベアメタルのAuto DevOps要件](#auto-devops-requirements-for-bare-metal)を参照してください。

     {{< /alert >}}

- **ベースドメイン**（[Auto Review Apps](stages.md#auto-review-apps)および[Auto Deploy](stages.md#auto-deploy)用）

  すべてのAuto DevOpsアプリケーションで使用される[Auto DevOpsのベースドメインを指定](#auto-devops-base-domain)する必要があります。このドメインにはワイルドカードDNSを設定する必要があります。

- **GitLab Runner**（すべてのステージ用）

  RunnerはDockerを実行するように設定する必要があります。通常、[Docker](https://docs.gitlab.com/runner/executors/docker.html) executorまたは[Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/) executorのいずれかを使用し、[特権モードを有効](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode)にします。RunnerをKubernetesクラスターにインストールする必要はありませんが、Kubernetes executorは使いやすく、自動的にオートスケールします。[Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine.html)を使用して、DockerベースのRunnerがオートスケールするように設定することもできます。

  Runnerは、GitLabインスタンス全体で使用できる[インスタンスRunner](../../ci/runners/runners_scope.md#instance-runners)として登録するか、特定のプロジェクトに割り当てる[プロジェクトRunner](../../ci/runners/runners_scope.md#project-runners)として登録する必要があります。

- **cert-manager**（オプション、TLS/HTTPS用）

  アプリケーションのHTTPSエンドポイントを有効にするには、[cert-managerをインストール](https://cert-manager.io/docs/releases/)します。これは証明書の発行に役立つ、ネイティブのKubernetes証明書管理コントローラーです。クラスターにcert-managerをインストールすると、[Let's Encrypt](https://letsencrypt.org/)証明書が発行され、証明書が有効で最新の状態であることが保証されます。

KubernetesまたはPrometheusが設定されていない場合、[Auto Review Apps](stages.md#auto-review-apps)と[Auto Deploy](stages.md#auto-deploy)はスキップされます。

すべての要件を満たしたら、[Auto DevOpsを有効](_index.md#enable-or-disable-auto-devops)にできます。

## ベアメタルのAuto DevOps要件 {#auto-devops-requirements-for-bare-metal}

[Kubernetes Ingress-NGINX](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/)ドキュメントから引用:

> ネットワークロードバランサーがオンデマンドで利用できる従来のクラウド環境では、1つのKubernetesマニフェストで、NGINX Ingressコントローラーへの単一の接続ポイントを外部クライアントに提供し、それを通じてクラスター内で実行されているすべてのアプリケーションに間接的にアクセスできます。ベアメタル環境にはこのような仕組みが備わっていないため、外部コンシューマーに同様のアクセスを提供するには、少し異なるセットアップが必要です。

上記のリンク先ドキュメントでは、この問題について説明し、利用可能な解決策を提示しています。次に例を示します。

- [MetalLB](https://github.com/metallb/metallb)を使用する。
- [PorterLB](https://github.com/kubesphere/porterlb)を使用する。
