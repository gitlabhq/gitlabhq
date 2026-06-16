---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: アプリケーションのパフォーマンスをモニタリングし、パフォーマンスに関するイシューをトラブルシューティングを行う。
ignore_in_report: true
title: 可観測性
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.1で、すべてのユーザーが利用できる実験的な機能として[導入](https://gitlab.com/gitlab-org/embody-team/experimental-observability/documentation/-/work_items/6)されました。

{{< /history >}}

GitLab可観測性は、分散トレーシング、メトリクス、ログをすべて1つのプラットフォームで提供します。カーディナリティの制限はありません。チームが学習するための別のツールは不要です。

GitLab可観測性を使用すると、次のことができます:

- マイクロサービス間の分散トレーシングにより、アプリケーションパフォーマンスをモニタリングします。
- コード変更を本番環境のイシューと関連付けます。
- コードを変更することなく、CI/CDパイプラインを自動的にインストゥルメントします。
- OpenTelemetry標準を使用して、制限なしで高カーディナリティのメトリクスを送信します。

GitLab可観測性は、積極的に進化している実験的な機能です。トレース、ログ、およびメトリクスの送信を今すぐ開始できます。ワークフローに慣れるには、まず重要でないサービスで試してから、必要に応じて使用範囲を展開してください。

<i class="fa-youtube-play" aria-hidden="true"></i>詳細については、[GitLab可観測性（O11y）入門](https://www.youtube.com/watch?v=XI9ZruyNEgs)を参照してください。
<!-- Video published on 2025-06-18 -->

GitLab可観測性は、すべてのティアで利用可能であり、Freeです。[フィードバックを共有するか、機能をリクエスト](#share-your-feedback)してください。

## 始める {#get-started}

1. 可観測性を、[お使いのGitLab Self-Managedインスタンス](setup_self_managed.md) 、または[GitLab.com](setup_gitlab_com.md)のいずれかにセットアップします。
1. OTLPエンドポイントを追加して[テレメトリの送信を開始](send.md)するか、[CI/CDパイプラインテレメトリを表示](ci_cd.md)します。
1. 最初のトレースを表示します。
1. 低速なリクエストをデバッグします。

<div class="video-fallback">
  動画:<a href="https://www.youtube.com/watch?v=lZtgor6chMs">GitLab可観測性のセットアップ</a>。
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/lZtgor6chMs" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2026-05-04 -->

## 実際の使用例 {#real-world-usage}

GitLab可観測性は、世界中のチームがアプリケーションとインフラストラクチャをモニタリングするために使用されています。

<!-- TODO: Add usage demonstration video showing real debugging workflow
<i class="fa-youtube-play" aria-hidden="true"></i>
For a usage demonstration, see [How to Debug Production Issues with GitLab Observability](VIDEO_URL).
-->

（2026年4月21日の週現在）当社のユーザーは、GitLab.com上でGitLab可観測性を使用してシステムを積極的にモニタリングしています:

- 毎日5700万を超えるトレースが処理されています。
- 3,000を超えるサービスが積極的にモニタリングされています。

## 主な機能 {#key-features}

### パフォーマンスをモニタリングし、イシューをトレースする {#monitor-performance-trace-issues}

イシューをより迅速に見つけてデバッグします。

- 強化された開発ワークフロー。コードの変更をアプリケーションのパフォーマンスメトリクスと直接関連付け、デプロイがイシューを発生させた時期を特定します。
- 効率化されたインシデント対応。最近のデプロイ、コードの変更、および関連するデベロッパーを1か所で確認できます。

イシューが発生した場合、以下を表示します:

- 低速なクエリを示すパフォーマンストレース。
- 変更を導入したマージリクエスト。
- それを修正できるデベロッパー。
- それをロールアウトしたデプロイ。

### 統合されたプラットフォーム {#unified-platform}

次のものを組み合わせた統合ダッシュボードを通じて、アプリケーションパフォーマンスをモニタリングします:

- 分散トレーシング。マイクロサービス全体のリクエストを追跡して、ボトルネックを特定します。
- メトリクス。アプリケーションとインフラストラクチャのパフォーマンスを長期的に追跡します。
- ログ。ログエントリをトレースおよびメトリクスと関連付けて、完全なコンテキストを取得します。

一元化された管理により、以下が提供されます:

- 簡素化されたアクセス管理。新しいエンジニアは、コードリポジトリへのアクセスを受け取ると、自動的に本番環境の可観測性データにアクセスできるようになります。
- コンテキスト切り替えなし。GitLabを離れることなくモニタリングデータにアクセスできます。

### デベロッパーにとって使いやすいインテグレーション {#developer-friendly-integration}

GitLab可観測性を評価しながら、同じOpenTelemetryデータを複数のバックエンドに送信します。

- DatadogまたはNew Relicから移行します。OpenTelemetryを使用している場合は、OTLPエンドポイントを変更するだけです。
- ベンダーロックインなし。標準のOpenTelemetryインストゥルメンテーションライブラリを使用します。OTLPエンドポイントを変更することで、いつでもプロバイダーを切り替えられます。

### 迅速なセットアップとインストゥルメンテーション {#fast-setup-and-instrumentation}

ほとんどのチームは、機能を有効にしてから5〜10分以内に最初のトレースを確認しています。

- 事前構築済みのダッシュボード。一般的なユースケースのテンプレートから始めます。
- 自動CI/CDインストゥルメンテーション。1つの環境変数を設定すると、GitLabがCI/CDパイプラインを自動的にインストゥルメントします。

### コスト効率が高く、スケーラブル {#cost-effective-and-scalable}

- すべてのティアでFreeです。シートごと、メトリクスごと、またはホストごとの課金はありません。トレース、メトリクス、またはログに制限はありません。
- カーディナリティの制限はありません。コストを気にすることなく、高カーディナリティのメトリクスを送信します。
- オープンソースモデル。機能や修正を直接コントリビュートします。
- 予測可能なコスト。メトリクスの急増による予期せぬ請求はありません。

### コンプライアンスと監査証跡 {#compliance-and-audit-trails}

このインテグレーションは、コード変更をシステム動作にリンクする包括的な監査証跡を作成し、コンプライアンス要件とインシデント後の分析に役立ちます。

## 詳しく見る {#learn-more}

- [OpenTelemetryドキュメント](https://opentelemetry.io/docs/instrumentation/)。言語固有のインストゥルメンテーションガイド。
- [GitLab可観測性テンプレート](https://gitlab.com/gitlab-org/embody-team/experimental-observability/o11y-templates/)。事前構築済みのダッシュボードと例。
- [提案された機能](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues/8)

## ヘルプの参照 {#get-help}

- [Discordコミュニティ](https://discord.com/channels/778180511088640070/1379585187909861546)。他のユーザーとの会話に参加します。
- [GitLabイシュー](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues)。バグを報告するか、機能をリクエストします。
- [トラブルシューティング情報](troubleshooting.md)。

## フィードバックを共有 {#share-your-feedback}

GitLab可観測性は、ユーザーのフィードバックに基づいて強化されています。フィードバックを提供するには:

- [Discordチャンネル](https://discord.com/channels/778180511088640070/1379585187909861546)に参加します。
- [イシューを開いて](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues)バグを報告するか、機能をリクエストします。
