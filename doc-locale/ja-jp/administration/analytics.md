---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: GitLabでのデータ分析のためにClickHouseを有効化し、設定します。
title: ClickHouseをレポート分析に使用します
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- ClickHouseのデータコレクタ―は、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/414610)されました。`clickhouse_data_collection`という名前の[機能フラグ](feature_flags/_index.md)付きです。デフォルトでは無効になっています。
- 機能フラグ`clickhouse_data_collection`はGitLab 17.0で削除され、アプリケーション設定に置き換えられました。

{{< /history >}}

[コントリビュート分析レポート](../user/group/contribution_analytics/_index.md) 、[CI/CD分析ダッシュボード](../user/analytics/ci_cd_analytics.md) 、[Value Streams Dashboard](../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports)のコントリビューター数メトリクスは、データソースとしてClickHouseを使用できます。

前提要件: 

- インスタンスで[ClickHouseを設定](../integration/clickhouse.md)する必要があります。

ClickHouseを有効にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. 左側のサイドバーの下部にある**分析**を選択し、**ClickHouseを有効にする**チェックボックスを選択します。
