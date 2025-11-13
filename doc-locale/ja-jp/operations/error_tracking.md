---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: エラートラッキング
description: エラー追跡、ロギング、デバッグ、およびデータ保持。
---

エラー追跡は、デベロッパーがアプリケーションによって生成されたエラーを発見して表示するのに役立ちます。エラー情報がコードが開発された場所に表示されるため、エラー追跡により、効率性と認識が向上します。ユーザーは、[GitLab統合エラー追跡](integrated_error_tracking.md)と[Sentryベース](sentry_error_tracking.md)のバックエンドを選択できます。

## 前提要件 {#prerequisites}

エラー追跡を機能させるには、以下が必要です:

- **Your application configured with the Sentry SDK**（Sentry SDKで構成されたアプリケーション）: エラーが発生すると、Sentry SDKがその情報をキャプチャし、ネットワーク経由でバックエンドに送信します。バックエンドは、すべてのエラーに関する情報を保存します。
- **バックエンドのトラッキングエラー**: バックエンドは、GitLab自体またはSentryのいずれかです。
  - GitLabバックエンドを使用するには、[GitLab統合エラー追跡](integrated_error_tracking.md)を参照してください。統合されたエラー追跡は、GitLab.comでのみ利用可能です。
  - Sentryをバックエンドとして使用するには、[Sentryエラー追跡](sentry_error_tracking.md)を参照してください。Sentryベースのエラー追跡は、GitLab.com、GitLab Dedicated、およびGitLab Self-Managedで利用できます。

## エラー追跡の仕組み {#how-error-tracking-works}

次の表は、各GitLab製品の機能の概要を示しています:

| 機能 | 利用可否設定 | データ収集 | データストレージ | データクエリ |
| ----------- | ----------- | ----------- | ----------- | ----------- |
| [GitLabに統合されたError Tracking](integrated_error_tracking.md) | GitLab.com | [Sentry SDK](https://github.com/getsentry/sentry?tab=readme-ov-file#official-sentry-sdks)を使用 | GitLab.comの場合 | GitLab.comを使用 |
| [Sentryベースのエラー追跡](sentry_error_tracking.md) | GitLab.com、GitLab Dedicated、GitLab Self-Managed | [Sentry SDK](https://github.com/getsentry/sentry?tab=readme-ov-file#official-sentry-sdks)を使用 | Sentryインスタンス（クラウドSentry.ioまたは[セルフホストSentry](https://develop.sentry.dev/self-hosted/)）上 | GitLab.comまたはSentryインスタンスを使用 |
