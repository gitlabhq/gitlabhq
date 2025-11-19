---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Grafanaを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GrafanaとGitLabをバンドルしたものは、GitLab 16.0で[非推奨](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7772)になりました。
- GrafanaとGitLabをバンドルしたものは、GitLab 16.3で[削除](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7772)されました。

{{< /history >}}

[Grafana](https://grafana.com/)は、グラフとダッシュボードを使用して、時系列メトリクスを視覚化できるツールです。GitLabはパフォーマンスデータをPrometheusに書き込みます。また、Grafanaを使用すると、データをクエリしてグラフを表示できます。

## GitLab UIとの連携 {#integrate-with-gitlab-ui}

Grafanaを設定した後、GitLabのサイドバーからアクセスするためのリンクを有効にできます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **メトリクスとプロファイリング**を選択します。
1. **メトリクス - Grafana**を展開します。
1. **Grafanaへのリンクを追加**チェックボックスを選択します。
1. **GrafanaのURL**を設定します。Grafanaインスタンスの完全なURLを入力します。
1. **変更を保存**を選択します。

GitLabは、**管理者**エリアの**モニタリング** > **メトリクスダッシュボード**にリンクを表示します。

## 必要なスコープ {#required-scopes}

以前のプロセスでGrafanaを設定するとき、**管理者**エリアの**アプリケーション** > **GitLab Grafana**の画面には、スコープは表示されません。ただし、`read_user`スコープは必須であり、アプリケーションに自動的に提供されます。`read_user`以外のスコープを設定すると、`read_user`も含めないと、OAuthプロバイダーとしてGitLabを使用してサインインしようとすると、次のエラーが発生します:

```plaintext
The requested scope is invalid, unknown, or malformed.
```

このエラーが表示された場合は、GitLab Grafana設定画面で、次のいずれかが当てはまることを確認してください:

- スコープが表示されない。
- `read_user`スコープが含まれています。
