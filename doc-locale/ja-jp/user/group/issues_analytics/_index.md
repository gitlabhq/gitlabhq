---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: イシュー分析
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

イシュー分析は、グループまたはプロジェクトで毎月作成されるイシューに関するインサイトを提供します。棒チャートは、毎月オープンおよびクローズされたイシューの数を示します。テーブルには、グローバルページフィルターに基づいて上位100件のイシューが表示され、各イシューに関する次の詳細が表示されます:

- 名前
- 経過時間
- ステータス
- マイルストーン
- イテレーション
- ウェイト
- 期限
- 担当者
- 作成者

![イシュー分析棒チャートとグループの表](img/issue_analytics_v17_8.png)

## イシュー分析を表示 {#view-issue-analytics}

イシュー分析を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。[新しいナビゲーションをオン](../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **分析** > **イシュー分析**を選択します。月ごとのイシューの合計数を表示するには、棒にカーソルを合わせるます。
1. オプション。結果をフィルタリングするには、**結果を検索またはフィルタリング**テキストボックスに条件を入力します:

   - 作成者
   - 担当者
   - マイルストーン
   - ラベル
   - 自分のリアクション
   - ウェイト

1. オプション。表示する合計月数を変更するには、パラメータ`months_back=n`をURLに追加します。たとえば、`https://gitlab.com/groups/gitlab-org/-/issues_analytics?months_back=15`は、GitLab.orgグループの15か月間のデータを含むチャートを表示します。

[Value Streams Dashboard](../../analytics/value_streams_dashboard.md)から、**新しいイシュー**ドリルダウンレポートを介してイシュー分析にアクセスすることもできます。

### 拡張イシュー分析 {#enhanced-issue-analytics}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.3で`issues_completed_analytics_feature_flag`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/233905/)されました。デフォルトでは無効になっています。
- GitLab 16.8で[GitLab.comとGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/437542)になりました。
- [機能フラグ`issues_completed_analytics_feature_flag`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146766)は、GitLab 16.10で削除されました。

{{< /history >}}

拡張イシュー分析は、追加のメトリクス`Issues closed`を表示します。これは、選択した期間にグループ内で解決されたイシューの合計数を表します。このメトリクスを使用して、全体的なターンアラウンド時間と顧客に提供される価値を向上させることができます。

![拡張イシュー分析棒チャートとグループの表](img/enhanced_issue_analytics_v17_8.png)
