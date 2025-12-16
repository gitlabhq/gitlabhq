---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: パフォーマンス、健全性、アップタイムのモニタリング
title: GitLabをモニタリングする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

次に、GitLabインスタンスをモニタリングするためのGitLabの機能について調査します:

- [パフォーマンスモニタリング](performance/_index.md): GitLabパフォーマンスモニタリングを使用すると、インスタンスのさまざまな統計を測定できます。
- [Prometheus](prometheus/_index.md): Prometheusは、GitLabおよびその他のソフトウェア製品のモニタリングに柔軟なプラットフォームを提供する、強力な時系列モニタリングサービスです。
- [GitHubインポート](github_imports.md): さまざまなPrometheusメトリクスを使用して、GitHubインポーターのヘルスチェックと進捗状況をモニタリングします。
- [アップタイムのモニタリング](health_check.md): ヘルスチェックエンドポイントを使用してサーバーの状態を確認します。
  - [IP許可リスト](ip_allowlist.md): プローブ時にヘルスチェック情報を提供するモニタリングエンドポイントのためにGitLabを設定します。
- [`nginx_status`](https://docs.gitlab.com/omnibus/settings/nginx.html#enablingdisabling-nginx_status): NGINXサーバーの状態をモニタリングします。
