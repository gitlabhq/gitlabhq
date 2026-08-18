---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: バリューストリーム分析データを取得する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GraphQL経由でステージのメトリクスの読み込みがGitLab 17.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/410327)。

{{< /history >}}

GraphQL APIを使用して、設定されたバリューストリームおよびバリューストリームステージからメトリクスをリクエストします。このデータは、バリューストリーム分析データを外部システムにエクスポートする場合や、レポートとして使用する場合に役立ちます。

次のメトリクスを利用できます。

- ステージ内の完了アイテム数。カウントは最大10,000アイテムに制限されています。
- ステージ内の完了アイテムの中央期間。
- ステージ内の完了アイテムの平均期間。

## 設定済みバリューストリームを取得する {#retrieve-configured-value-streams}

前提条件: 

- レポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。

まず、どのバリューストリームをレポートに使用するかを決定する必要があります。

グループの設定済みバリューストリームをリクエストするには、以下を実行します:

```graphql
group(fullPath: "your-group-path") {
  valueStreams {
    nodes {
      id
      name
    }
  }
}
```

同様に、プロジェクトのメトリクスをリクエストするには、以下を実行します:

```graphql
project(fullPath: "your-project-path") {
  valueStreams {
    nodes {
      id
      name
    }
  }
}
```

## ステージのメトリクスを取得する {#retrieve-metrics-for-a-stage}

バリューストリームのステージのメトリクスをリクエストするには、以下を実行します:

```graphql
group(fullPath: "your-group-path") {
  valueStreams(id: "your-value-stream-id") {
    nodes {
      stages {
        id
        name
      }
    }
  }
}
```

データの利用方法に応じて、特定のステージまたはバリューストリーム内のすべてのステージのメトリクスをリクエストできます。

> [!note]
> すべてのステージのメトリクスをリクエストすると、一部のインストールでは処理が遅すぎる場合があります。推奨されるアプローチは、ステージごとにメトリクスをリクエストすることです。

そのステージのメトリクスをリクエストする:

```graphql
group(fullPath: "your-group-path") {
  valueStreams(id: "your-value-stream-id") {
    nodes {
      stages(id: "your-stage-id") {
        id
        name
        metrics(timeframe: { start: "2024-03-01", end: "2024-03-31" }) {
          average {
            value
            unit
          }
          median {
            value
            unit
          }
          count {
            value
            unit
          }
        }
      }
    }
  }
}
```

> [!note]
> 常に指定された時間枠でメトリクスをリクエストする必要があります。最長でサポートされる時間枠は180日です。

この`metrics`ノードは追加のフィルタリングオプションをサポートしています:

- アサインされたユーザー名
- 作成者ユーザー名
- ラベル名
- マイルストーンのタイトル

フィルター付きのリクエスト例:

```graphql
group(fullPath: "your-group-path") {
  valueStreams(id: "your-value-stream-id") {
    nodes {
      stages(id: "your-stage-id") {
        id
        name
        metrics(
          labelNames: ["backend"],
          milestoneTitle: "17.0",
          timeframe: { start: "2024-03-01", end: "2024-03-31" }
        ) {
          average {
            value
            unit
          }
          median {
            value
            unit
          }
          count {
            value
            unit
          }
        }
      }
    }
  }
}
```

## ベストプラクティス {#best-practices}

- 現在のステータスを正確に把握するには、時間枠の終了にできるだけ近いタイミングでメトリクスをリクエストします。
- 定期的なレポート作成のために、スクリプトを作成し、[スケジュールされたパイプライン](../../ci/pipelines/schedules.md)機能を使用して、データをタイムリーにエクスポートすることができます。
- APIを呼び出すと、データベースから現在のデータが取得されます。時間の経過とともに、基礎となるデータベースのデータの変更により、同じメトリクスが変化する可能性があります。たとえば、グループからプロジェクトを移動または削除すると、グループレベルのメトリクスに影響を与える可能性があります。
- 以前の期間のメトリクスを再度リクエストし、以前に収集されたメトリクスと比較することで、データの偏りを示すことができ、変化する傾向を発見し説明するのに役立ちます。
