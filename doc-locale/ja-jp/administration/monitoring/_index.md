---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: パフォーマンス、健全性、アップタイムのモニタリング
title: GitLabをモニタリングする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

お使いのGitLabインスタンスをモニタリングするための機能をご覧ください:

- [パフォーマンスモニタリング](performance/_index.md): GitLabパフォーマンスモニタリングを使用すると、お使いのインスタンスのさまざまな統計を測定できます。
- [Prometheus](prometheus/_index.md): Prometheusは強力な時系列モニタリングサービスであり、GitLabやその他のソフトウェア製品をモニタリングするための柔軟なプラットフォームを提供します。
- [GitHubインポート](github_imports.md): GitHubインポーターの健全性と進捗状況を、さまざまなPrometheusメトリクスでモニタリングします。
- [モニタリングアップタイム](health_check.md): ヘルスチェックエンドポイントを使用してサーバーのステータスを確認します。
  - [IP許可リスト](ip_allowlist.md): GitLabを、プローブ時にヘルスチェック情報を提供するエンドポイントのモニタリング用に構成します。
- [`nginx_status`](https://docs.gitlab.com/omnibus/settings/nginx/#enablingdisabling-nginx_status): NGINXサーバーのステータスをモニタリングします。
