---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDを使用したインクリメンタルロールアウト
description: Kubernetes、CI/CD、リスク軽減、デプロイ。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

アプリケーションへの変更をロールアウトする場合、リスク軽減戦略として、Kubernetesポッドの一部にのみ本番環境環境の変更をリリースできます。本番環境環境への変更を段階的にリリースすることで、エラー率やパフォーマンスの低下を監視できます。問題がなければ、すべてのポッドを更新できます。

GitLabでは、インクリメンタルロールアウトを使用して、手動でトリガーされたロールアウトと、時間指定されたロールアウトの両方をKubernetesの本番環境システムでサポートしています。手動ロールアウトを使用する場合、各トランシェのポッドのリリースは手動でトリガーされます。時間指定ロールアウトでは、リリースはデフォルトの5分間の停止後、トランシェで実行されます。時間指定ロールアウトは、一時停止期間が終了する前に手動でトリガーすることもできます。

手動および時間指定のロールアウトは、[Auto DevOps](../../topics/autodevops/_index.md)で制御されるプロジェクトに自動的に含まれますが、`.gitlab-ci.yml`設定ファイルのGitLab CI/CDを介して設定することもできます。

手動でトリガーされたロールアウトは継続的デリバリーで実装できますが、時間指定のロールアウトは介入を必要とせず、継続的デプロイ戦略の一部にすることができます。必要に応じて手動で介入しない限り、アプリが自動的にデプロイされるように、両方を組み合わせることもできます。

以下のサンプルアプリケーションは、3つのオプションを示しています。これらを例として使用して、独自のものを構築できます:

- [手動による段階的なロールアウト](https://gitlab.com/gl-release/incremental-rollout-example/blob/master/.gitlab-ci.yml)
- [段階的なロールアウト](https://gitlab.com/gl-release/timed-rollout-example/blob/master/.gitlab-ci.yml)
- [手動と時間指定の両方のロールアウト](https://gitlab.com/gl-release/incremental-timed-rollout-example/blob/master/.gitlab-ci.yml)

## 手動ロールアウト {#manual-rollouts}

`.gitlab-ci.yml`を使用して、手動で段階的なロールアウトを実行するようにGitLabを設定できます。手動設定により、この機能をより詳細に制御できます。段階的なロールアウトのステップは、デプロイに定義されているポッドの数によって異なり、Kubernetesクラスターの作成時に設定されます。

たとえば、アプリケーションに10個のポッドがあり、10% のロールアウトジョブが実行される場合、アプリケーションの新しいインスタンスは1つのポッドにデプロイされ、残りのポッドにはアプリケーションの以前のインスタンスが表示されます。

まず、[テンプレートを手動として定義](https://gitlab.com/gl-release/incremental-rollout-example/blob/master/.gitlab-ci.yml#L100-103)します:

```yaml
.manual_rollout_template: &manual_rollout_template
  <<: *rollout_template
  stage: production
  when: manual
```

次に、[各ステップのロールアウト量を定義](https://gitlab.com/gl-release/incremental-rollout-example/blob/master/.gitlab-ci.yml#L152-155)します:

```yaml
rollout 10%:
  <<: *manual_rollout_template
  variables:
    ROLLOUT_PERCENTAGE: 10
```

ジョブがビルドされたら、ジョブ名の横にある**実行** ({{< icon name="play" >}}) を選択して、ポッドの各ステージングをリリースします。より低いパーセンテージのジョブを実行して、ロールバックすることもできます。100% に達すると、この方法を使用してロールバックすることはできません。デプロイをロールバックするには、[デプロイを再試行またはロールバックする](deployments.md#retry-or-roll-back-a-deployment)を参照してください。

[デプロイ](https://gitlab.com/gl-release/incremental-rollout-example)が利用可能であり、手動でトリガーされた段階的なロールアウトを示しています。

## 時間指定ロールアウト {#timed-rollouts}

時間指定ロールアウトは、各ジョブがデプロイする前に数分単位で遅延して定義されていることを除き、手動ロールアウトと同じように動作します。ジョブを選択すると、カウントダウンが表示されます。

![進行中の時間指定ロールアウト。](img/timed_rollout_v17_9.png)

この機能を段階的な手動ロールアウトと組み合わせることで、ジョブがカウントダウンしてからデプロイするようにすることができます。

まず、[テンプレートを時間指定として定義](https://gitlab.com/gl-release/timed-rollout-example/blob/master/.gitlab-ci.yml#L86-89)します:

```yaml
.timed_rollout_template: &timed_rollout_template
  <<: *rollout_template
  when: delayed
  start_in: 1 minutes
```

`start_in`キーを使用して遅延期間を定義できます:

```yaml
start_in: 1 minutes
```

次に、[各ステップのロールアウト量を定義](https://gitlab.com/gl-release/timed-rollout-example/blob/master/.gitlab-ci.yml#L97-101)します:

```yaml
timed rollout 30%:
  <<: *timed_rollout_template
  stage: timed rollout 30%
  variables:
    ROLLOUT_PERCENTAGE: 30
```

[デプロイ](https://gitlab.com/gl-release/timed-rollout-example)が利用可能で、[時間指定ロールアウトの設定を示しています](https://gitlab.com/gl-release/timed-rollout-example/blob/master/.gitlab-ci.yml#L86-95)。

## ブルー/グリーンデプロイ {#blue-green-deployment}

{{< alert type="note" >}}

チームはIngress注釈を利用し、ここで説明されているブルー/グリーンデプロイ戦略の代替アプローチとして[トラフィックウェイトを設定](../../user/project/canary_deployments.md#how-to-change-the-traffic-weight-on-a-canary-ingress-deprecated)できます。

{{< /alert >}}

A/Bデプロイまたはレッド/ブラックデプロイとも呼ばれるこの手法は、デプロイ中のダウンタイムとリスクを軽減するために使用されます。段階的なロールアウトと組み合わせることで、イシューを引き起こすデプロイの影響を最小限に抑えることができます。

この手法では、2つのデプロイがあります（「blue」と「green」ですが、任意の名前を使用できます）。これらのデプロイのうち、アクティブなのは一度に1つだけですが、段階的なロールアウト中は除きます。

たとえば、青色のデプロイを本番環境環境でアクティブにし、緑色のデプロイをテスト用に「ライブ」にすることができますが、本番環境環境にはデプロイしません。イシューが見つかった場合、緑色のデプロイは、本番環境環境のデプロイ（現在は青色）に影響を与えることなく更新できます。テストで問題が見つからない場合は、本番環境環境を緑色のデプロイに切り替え、青色は次のリリースをテストするために使用できるようになります。

このプロセスにより、別のデプロイに切り替えるために本番環境環境のデプロイを停止する必要がないため、ダウンタイムが短縮されます。両方のデプロイが並行して実行されており、いつでも切り替えることができます。

[のデプロイ例](https://gitlab.com/gl-release/blue-green-example)が、ブルー/グリーンデプロイを示す[`.gitlab-ci.yml` CI/CD設定ファイル](https://gitlab.com/gl-release/blue-green-example/blob/master/.gitlab-ci.yml)とともに利用できます。
