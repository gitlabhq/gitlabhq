---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループごとのDevOps導入状況
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.6で[Registration Features Program](../../../administration/settings/usage_statistics.md#registration-features-program)に[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/367093)されました。

{{< /history >}}

DevOpsの導入は、組織内のグループがGitLabの機能をどのように導入して使用しているかを示します。この情報は、グループと[インスタンス](../../../administration/analytics/devops_adoption.md)で利用できます。

グループのDevOps導入を使用して以下を行います:

- GitLabの機能の導入がラグしているサブグループを特定し、DevOpsの過程をガイドします。
- 特定の機能を導入したサブグループを見つけ、他のサブグループにそれらの機能の使用方法に関するガイダンスを提供します。
- GitLabから期待される投資収益率を得られているか確認します。

## 機能の導入 {#feature-adoption}

DevOps導入は、開発、セキュリティ、および運用に関する機能の導入状況を示します。

| カテゴリ    | 機能 |
|-------------|---------|
| 開発 | 承認<br>コードオーナー<br>イシュー<br>マージリクエスト |
| セキュリティ    | DAST<br>依存関係スキャン<br>ファズテスト<br>SAST |
| Ops  | デプロイ<br>パイプライン<br>Runner |

機能は、グループまたはサブグループが直近の1か月間にプロジェクトでその機能を使用したときに**導入済み**として表示されます。たとえば、あるグループのプロジェクトでイシューが作成された場合、そのグループはその期間にイシューを導入したことになります。

![グループのDevOps導入レポート](img/devops_adoption_v17_8.png)

**概要**タブには以下が示されています:

- 導入された機能の総数。
- 各カテゴリで採用されている機能。
- **徐々にアドプションする**棒チャートの月ごとの各カテゴリで採用されている機能の数。このチャートには、グループのDevOps導入を有効にした日付からのデータのみが表示されます。
- **サブグループごとの導入率**テーブルのサブグループごとの各カテゴリで採用されている機能の数。

**Dev**、**Sec**、**Ops**タブは、サブグループごとの開発、セキュリティ、および運用で採用されている機能を示しています。

DevOps導入レポートは以下を除外します:

- 休止プロジェクト。機能を使用するプロジェクトの数は考慮されません。多数の休止プロジェクトがあっても、導入は低下しません。
- 新しいGitLabの機能。導入は、採用された機能の合計数であり、機能の割合ではありません。

## データ処理 {#data-processing}

毎週のタスクは、DevOps導入のデータを処理します。このタスクは、グループのDevOps導入に初めてアクセスするまで無効になっています。

データ処理タスクは、毎月1日にデータを更新します。毎月の更新が失敗した場合、タスクは成功するまで毎日試行します。

GitLabがグループのデータを処理している間、DevOpsの導入データが表示されるまでに最大1分かかる場合があります。

## グループのDevOps導入を表示 {#view-devops-adoption-for-groups}

前提要件: 

- グループのレポーターロール以上が必要です。

DevOps導入を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**分析** > **DevOpsの導入**を選択します。
1. 月ごとのカテゴリ別に採用された機能を表示するには、バーにカーソルを合わせる。

## サブグループをDevOps導入に追加 {#add-a-subgroup-to-devops-adoption}

前提要件: 

- グループのレポーターロール以上が必要です。

サブグループをDevOps導入レポートに追加するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**分析** > **DevOpsの導入**を選択します。
1. **サブグループを追加または削除**ドロップダウンリストから、追加するサブグループを選択します。

## DevOps導入からサブグループを削除 {#remove-a-subgroup-from-devops-adoption}

前提要件: 

- グループのレポーターロール以上が必要です。

DevOps導入レポートからサブグループを削除するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**分析** > **DevOpsの導入**を選択します。
1. 次のいずれかの操作を行います:

- **サブグループを追加または削除**ドロップダウンリストから、削除するサブグループをクリアします。
- **サブグループごとの導入率**テーブルで、削除するグループの行から**Remove Group from the table**（テーブルからグループを削除）（{{< icon name="remove" >}}）を選択します。
