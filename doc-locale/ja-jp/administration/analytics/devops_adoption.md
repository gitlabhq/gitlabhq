---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabインスタンスでのDevSecOpsの導入を監視し、機能の使用状況を追跡し、チームのパフォーマンスに関するインサイトを取得します。
title: インスタンスごとのDevOps導入状況
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

DevOpsの導入状況では、開発、セキュリティ、運用機能のインスタンス全体の導入状況と、DevOpsスコアの概要を把握できます。

この機能の詳細については、[グループごとのDevOpsの導入](../../user/group/devops_adoption/_index.md)も参照してください。

## DevOpsスコア {#devops-score}

{{< alert type="note" >}}

DevOpsスコアを表示するには、GitLabインスタンスの[Service Ping](../settings/usage_statistics.md#service-ping)を有効にする必要があります。DevOpsスコアは比較ツールであるため、スコアデータはまずGitLab社で一元的に処理される必要があります。Service Pingが有効になっていない場合、DevOpsスコアの値は0です。

{{< /alert >}}

DevOpsスコアを使用すると、組織のDevOpsの状況を他の組織と比較できます。

**DevOpsスコア**には、請求対象ユーザー数で平均した、過去30日間のインスタンスでの主なGitLab機能の使用状況が表示されます。

- **スコア**は、機能スコアの平均を表します。
- **使用状況**は、過去30日間の請求対象ユーザー1人あたりの機能の平均使用状況を表します。
- **リーダーの使用状況**は、GitLabが収集した[Service Pingデータ](../settings/usage_statistics.md#service-ping)に基づいて、上位のインスタンスから計算されます。

Service Pingデータは、分析のためにGitLabサーバー上で集計されます。お客様の使用状況情報は、他のGitLabインスタンスには**not sent**（送信されません）。GitLabを使い始めたばかりの場合、この機能が利用可能になるまで、データの収集に数週間かかることがあります。

## DevOpsの導入状況を表示する {#view-devops-adoption}

インスタンスのDevOps導入状況を表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **分析** > **DevOpsの導入**を選択します。

## DevOps導入へのグループの追加 {#add-a-group-to-devops-adoption}

前提要件: 

- グループのレポーターロール以上が必要です。

DevOps導入にグループを追加するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **分析** > **DevOpsの導入**を選択します。
1. **グループを追加または削除**ドロップダウンリストから、追加するグループを選択します。

## DevOps導入からのグループの削除 {#remove-a-group-from-devops-adoption}

前提要件: 

- グループのレポーターロール以上が必要です。

DevOps導入からグループを削除するには:

1. 左側のサイドバーの下部で、**管理者エリア**を選択します。
1. **分析** > **DevOpsの導入**を選択します。
1. 次のいずれかの操作を行います:

- **グループを追加または削除**ドロップダウンリストで、削除するグループをクリアします。
- **グループごとの導入率**テーブルで、削除するグループの行にある**Remove Group from the table**（テーブルからグループを削除）（{{< icon name="remove" >}}）を選択します。
