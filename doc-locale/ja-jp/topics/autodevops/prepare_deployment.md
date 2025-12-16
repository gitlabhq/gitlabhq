---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Auto DevOpsをデプロイに備える
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ベースドメインとデプロイ戦略を設定せずにAuto DevOpsを有効にすると、GitLabはアプリケーションを直接デプロイできません。したがって、Auto DevOpsを有効にする前に、それらを準備することをお勧めします。

## デプロイ戦略 {#deployment-strategy}

Auto DevOpsを使用してアプリケーションをデプロイする場合は、ニーズに最適な[継続的デプロイ戦略](../../ci/_index.md)を選択してください:

| デプロイ戦略                                                     | セットアップ | 開発手法 |
|-------------------------------------------------------------------------|-------|-------------|
| **本番環境への継続的デプロイ**                                 | デフォルトブランチを本番環境に継続的にデプロイするための[Auto Deploy](stages.md#auto-deploy)を有効にします。 | 本番環境への継続的デプロイ。|
| **スケジュールされた増分ロールアウトを用いた本番環境への継続的デプロイ** | [`INCREMENTAL_ROLLOUT_MODE`](cicd_variables.md#timed-incremental-rollout-to-production)変数を`timed`に設定します。 | ロールアウト間に5分の遅延を設けて、本番環境に継続的にデプロイします。 |
| **Stagingステージへの自動デプロイ、本番環境への手動デプロイ**    | [`STAGING_ENABLED`](cicd_variables.md#deploy-policy-for-staging-and-production-environments)を`1`に、[`INCREMENTAL_ROLLOUT_MODE`](cicd_variables.md#incremental-rollout-to-production)を`manual`に設定します。 | デフォルトブランチを継続的にステージングにデプロイし、本番環境には継続的デリバリーを行います。 |

デプロイ方法は、Auto DevOpsを有効にする際、または後から選択できます:

1. GitLabで、プロジェクトの**設定** > **CI/CD** > **Auto DevOps**に移動します。
1. デプロイ戦略を選択します。
1. **変更を保存**を選択します。

{{< alert type="note" >}}

ダウンタイムとリスクを最小限に抑えるため、[ブルー/グリーンデプロイ](../../ci/environments/incremental_rollouts.md#blue-green-deployment)手法を使用してください。

{{< /alert >}}

## Auto DevOpsのベースドメイン {#auto-devops-base-domain}

[Auto Review Apps](stages.md#auto-review-apps)と[Auto Deploy](stages.md#auto-deploy)を使用するには、Auto DevOpsのベースドメインが必要です。

ベースドメインを定義するには、次のいずれかを実行します:

- プロジェクト、グループ、またはインスタンスで、設定に移動して追加します。
- プロジェクトまたはグループで、環境変数として`KUBE_INGRESS_BASE_DOMAIN`を追加します。
- インスタンスで、**管理者**エリアに移動し、**設定** > **CI/CD** > **Continuous Integration and Delivery**（継続的インテグレーションとデリバリー）に移動して追加します。

ベースドメイン変数`KUBE_INGRESS_BASE_DOMAIN`は、他の環境変数と優先順位が同じ[変数](../../ci/variables/_index.md#cicd-variable-precedence)に従います。

プロジェクトとグループでベースドメインを指定しない場合、Auto DevOpsはインスタンス全体の**Auto DevOpsドメイン**を使用します。

Auto DevOpsには、ベースドメインに一致するワイルドカードDNS `A`レコードが必要です。ベースドメインが`example.com`の場合、次のようなDNSエントリが必要です:

```plaintext
*.example.com   3600     A     10.0.2.2
```

この場合、デプロイされたアプリケーションは`example.com`から提供され、`10.0.2.2`はロードバランサー（一般的にはNGINX）のIPアドレスです（[要件を参照](requirements.md)）。DNSレコードのセットアップは、このドキュメントの範囲外です。詳細については、DNSプロバイダーにお問い合わせください。

または、設定なしで自動ワイルドカードDNSを提供する無料のパブリックサービス（[nip.io](https://nip.io)など）を使用することもできます。[nip.io](https://nip.io)の場合、Auto DevOpsのベースドメインを`10.0.2.2.nip.io`に設定します。

セットアップが完了すると、すべてのリクエストはロードバランサーに到達し、ロードバランサーはアプリケーションを実行しているKubernetesポッドにリクエストをルーティングします。
