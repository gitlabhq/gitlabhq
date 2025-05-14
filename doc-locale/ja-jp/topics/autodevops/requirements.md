---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Auto DevOpsの要件
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Auto DevOps](_index.md)を有効にする前に、デプロイに向けて準備することをお勧めします。準備しない場合は、これを使用してアプリをビルドおよびテストし、後でデプロイを設定できます。

デプロイを準備するには:

1. [デプロイ戦略](#auto-devops-deployment-strategy)を定義します。
1. [ベースドメイン](#auto-devops-base-domain)を準備します。
1. デプロイ先を定義します。

   1. [Kubernetes](#auto-devops-requirements-for-kubernetes)
   1. [Amazon Elastic Container Service（ECS）](cloud_deployments/auto_devops_with_ecs.md)
   1. [Amazon Elastic Kubernetes Service（EKS）](https://about.gitlab.com/blog/2020/05/05/deploying-application-eks/)
   1. [Amazon EC2](cloud_deployments/auto_devops_with_ec2.md)
   1. [Google Kubernetes Engine](cloud_deployments/auto_devops_with_gke.md)
   1. [ベアメタル](#auto-devops-requirements-for-bare-metal)

1. [Auto DevOpsを有効にします](_index.md#enable-or-disable-auto-devops)。

## Auto DevOpsのデプロイ戦略

Auto DevOpsを使用してアプリケーションをデプロイする場合は、ニーズに最適な[継続的デプロイメント戦略](../../ci/_index.md)を選択してください。

| デプロイ戦略 | セットアップ | 開発手法 |
|--|--|--|
| **本番環境への継続的デプロイメント** | 本番環境に継続的にデプロイされるデフォルトブランチで[Auto Deploy](stages.md#auto-deploy)を有効にします。 | 本番環境への継続的デプロイメント。|
| **時間指定の段階的ロールアウトを使用した本番環境への継続的デプロイメント** | [`INCREMENTAL_ROLLOUT_MODE`](cicd_variables.md#timed-incremental-rollout-to-production)変数を`timed`に設定します。 | ロールアウト間に5分の遅延を設けて、本番環境に継続的にデプロイします。 |
| **stagingステージへの自動デプロイ、本番環境への手動デプロイ** | [`STAGING_ENABLED`](cicd_variables.md#deploy-policy-for-staging-and-production-environments)を`1`に、[`INCREMENTAL_ROLLOUT_MODE`](cicd_variables.md#incremental-rollout-to-production)を`manual`に設定します。 | デフォルトブランチはstagingステージに継続的にデプロイされ、本番環境に継続的にデリバリーされます。 |

デプロイ方法はAuto DevOpsを有効にする際、または後から選択できます。

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **Auto DevOps**を展開します。
1. デプロイ戦略を選択します。
1. **変更を保存**を選択します。

{{< alert type="note" >}}

[ブルー/グリーンデプロイ](../../ci/environments/incremental_rollouts.md#blue-green-deployment)手法を使用して、ダウンタイムとリスクを最小限に抑えます。

{{< /alert >}}

## Auto DevOpsベースドメイン

[Auto Review Apps](stages.md#auto-review-apps)と[Auto Deploy](stages.md#auto-deploy)を使用するには、Auto DevOpsベースドメインが必要です。

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

この場合、デプロイされたアプリケーションは`example.com`から提供され、`10.0.2.2`はロードバランサー、通常はNGINXのIPアドレスです（[要件を参照](requirements.md)）。DNSレコードのセットアップはこのドキュメントの範囲外です。詳細については、DNSプロバイダーにお問い合わせください。

または、設定なしで自動ワイルドカードDNSを提供する無料のパブリックサービス（[nip.io](https://nip.io)など）を使用することもできます。[nip.io](https://nip.io)の場合、Auto DevOpsベースドメインを`10.0.2.2.nip.io`に設定します。

セットアップが完了すると、すべてのリクエストはロードバランサーに到達し、ロードバランサーはアプリケーションを実行しているKubernetesポッドにリクエストをルーティングします。

## KubernetesのAuto DevOps要件

KubernetesでAuto DevOpsを最大限に活用するには、以下が必要です。

- **Kubernetes**（[Auto Review Apps](stages.md#auto-review-apps)および[Auto Deploy](stages.md#auto-deploy)用）

  デプロイを有効にするには、以下が必要です。

  1. プロジェクト用の[Kubernetes 1.12+クラスター](../../user/infrastructure/clusters/_index.md)。Kubernetes 1.16+クラスターの場合、[Kubernetes 1.16+用のAuto Deploy](stages.md#kubernetes-116)の追加設定を実行する必要があります。
  1. 外部HTTPトラフィックの場合、Ingressコントローラーが必要です。通常のデプロイの場合、どのIngressコントローラーでも動作するはずですが、GitLab 14.0の時点では、[カナリアデプロイ](../../user/project/canary_deployments.md)にはNGINX Ingressが必要です。GitLab [クラスター管理プロジェクトテンプレート](../../user/clusters/management_project_template.md)を使用するか、[`ingress-nginx`](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx) Helmチャートを使用して手動で、NGINX IngressコントローラーをKubernetesクラスターにデプロイできます。

     [カスタムチャートを使用して](customize.md#custom-helm-chart)デプロイする場合は、`prometheus.io/scrape: "true"`および`prometheus.io/port: "10254"`を使用して、PrometheusによってスクレイピングされるようにIngressマニフェストに[アノテーションを付ける](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)必要があります。

     {{< alert type="note" >}}

     クラスターがベアメタルにインストールされている場合は、「[ベアメタルのAuto DevOps要件](#auto-devops-requirements-for-bare-metal)」を参照してください。

     {{< /alert >}}

- **ベースドメイン**（[Auto Review Apps](stages.md#auto-review-apps)および[Auto Deploy](stages.md#auto-deploy)用）

  [Auto DevOpsベースドメインを指定する](#auto-devops-base-domain)必要があります。これは、すべてのAuto DevOpsアプリケーションで使用されます。このドメインは、ワイルドカードDNSで設定する必要があります。

- **GitLab Runner**（すべてのステージ用）

  通常は[Docker](https://docs.gitlab.com/runner/executors/docker.html) executorまたは[Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/) executorのいずれかを使用し、[特権モードを有効](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode)にして、Dockerを実行するようにRunnerを設定する必要があります。RunnerをKubernetesクラスターにインストールする必要はありませんが、Kubernetes executorは使いやすく、自動スケールします。[Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine.html)を使用して、DockerベースのRunnerを自動スケールするように設定することもできます。

  Runnerは、GitLabインスタンス全体の[インスタンスRunner](../../ci/runners/runners_scope.md#instance-runners)、または特定のプロジェクトに割り当てられた[プロジェクトRunner](../../ci/runners/runners_scope.md#project-runners)として登録する必要があります。

- **cert-manager**（オプション、TLS/HTTPS用）

  アプリケーションのHTTPSエンドポイントを有効にするには、[cert-managerをインストール](https://cert-manager.io/docs/releases/)できます。これは、証明書の発行に役立つネイティブKubernetes証明書管理コントローラーです。クラスターにcert-managerをインストールすると、[Let's Encrypt](https://letsencrypt.org/)証明書が発行され、証明書が有効で最新の状態であることが保証されます。

KubernetesまたはPrometheusが設定されていない場合、[Auto Review Apps](stages.md#auto-review-apps)と[Auto Deploy](stages.md#auto-deploy)はスキップされます。

すべての要件を満たしたら、[Auto DevOpsを有効に](_index.md#enable-or-disable-auto-devops)できます。

## ベアメタルのAuto DevOps要件

[Kubernetes Ingress-NGINXドキュメント](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/)から引用:

> ネットワークロードバランサーがオンデマンドで利用できる従来のクラウド環境では、1つのKubernetesマニフェストで、単一の連絡先をNGINX Ingressコントローラー、外部のクライアント、間接的にクラスター内で実行されているすべてのアプリケーションに提供できます。ベアメタル環境にはこのような機能がないため、外部コンシューマーに同じ種類のアクセスを提供するには、少し異なるセットアップが必要です。

上記のドキュメントでは、問題について説明し、考えられる解決策を示しています。たとえば、次のような解決策があります。

- [MetalLB](https://github.com/metallb/metallb)経由
- [PorterLB](https://github.com/kubesphere/porterlb)経由
