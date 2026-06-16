---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: アプリケーションのパフォーマンスをモニタリングし、パフォーマンスに関するイシューをトラブルシューティングを行う。
ignore_in_report: true
title: CI/CDパイプラインのテレメトリを可観測性として表示
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

有効にすると、GitLab可観測性はCI/CDパイプラインを自動的に計測し、コードを変更することなく、パイプラインのパフォーマンス、ジョブの実行時間、実行フローの表示レベルを提供します。

- どのジョブがパイプラインを遅くしているかの表示レベル。
- パイプラインのパフォーマンスが時間の経過とともにどのように変化するか。
- お使いのデプロイプロセスにおけるボトルネック。

## パイプラインの計測を有効にする {#enable-pipeline-instrumentation}

自動パイプライン計測を有効にするには、`GITLAB_OBSERVABILITY_EXPORT` CI/CD変数をプロジェクトまたはグループに追加します:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **変数を追加**を選択します。
1. 変数を設定します:
   - **キー**: `GITLAB_OBSERVABILITY_EXPORT`
   - **値**: `traces`、`metrics`、`logs`のうち1つ以上 (複数の値を指定する場合はカンマ区切り)
   - **タイプ**: 変数
   - **環境範囲**: すべて (または特定の環境)
1. **変数を追加**を選択します。

## 計測の種類 {#instrumentation-types}

`GITLAB_OBSERVABILITY_EXPORT`変数は次の値を受け入れます:

- `traces`: パイプラインの実行フロー、ジョブの依存関係、およびタイミングを示す分散トレースをエクスポートする
- `metrics`: パイプラインの期間、ジョブの成功率、およびリソース使用量に関するメトリクスをエクスポートする
- `logs`: パイプラインの実行からの構造化ログをエクスポートする

複数の種類をカンマで区切って有効にできます:

```plaintext
traces,metrics,logs
```

## 仕組み {#how-it-works}

変数が設定されると、GitLabは自動的に以下を実行します:

1. 各パイプラインが完了した後、パイプラインの実行データをキャプチャします
1. データを設定に基づいてOpenTelemetry形式に変換します
1. テレメトリデータをGitLab可観測性インスタンスにエクスポートする
1. データを可観測性ダッシュボードで利用できるようにします

お使いの`.gitlab-ci.yml`ファイルへの変更は必要ありません。計測はバックグラウンドで自動的に行われます。

## パイプラインのテレメトリを表示 {#view-pipeline-telemetry}

計測が有効なパイプラインを実行した後:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**可観測性** > **サービス**を選択します。
1. `gitlab-ci`サービスを選択して、パイプライン実行からのトレース、メトリクス、およびログを表示します。

[GitLab Observability Templates](https://gitlab.com/gitlab-org/embody-team/experimental-observability/o11y-templates/)からのCI/CDダッシュボードテンプレートは、パイプラインのパフォーマンス分析のための事前構築済み視覚化を提供します。

## 関連トピック {#related-topics}

- [可観測性のトラブルシューティング](troubleshooting.md)
