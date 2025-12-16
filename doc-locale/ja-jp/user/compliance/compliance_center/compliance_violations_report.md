---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンプライアンス違反レポート
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.9で、[名前がコンプライアンス違反レポートに変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112111)。
- コンプライアンスフレームワークを作成および編集する機能がGitLab 16.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/394950)。
- 新しい動的コンプライアンス違反レポートが、`compliance_violations_report`および`enable_project_compliance_violations`という[フラグ](../../../administration/feature_flags/_index.md)付きでGitLab 18.2で[導入されました](https://gitlab.com/groups/gitlab-org/-/epics/12774)。デフォルトでは無効になっています。
- `compliance_violations_report`と`enable_project_compliance_violations`は、GitLab 18.3で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201027)になっています。
- `compliance_violations_report`および`enable_project_compliance_violations`は、GitLab 18.5で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201027)されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。本番環境で使用する場合は、引き続き[静的コンプライアンス違反レポート](#static-compliance-violations-report)を使用してください。

{{< /alert >}}

GitLabのコンプライアンス違反レポートを使用すると、グループ内のすべてのプロジェクトにわたるコンプライアンス違反の包括的なビューを確認できます。このレポートには、違反したコントロール、関連する監査イベントに関する詳細な情報が記載されており、違反ステータスを管理できます。

## コンプライアンス違反レポートを表示する {#view-the-compliance-violations-report}

前提要件: 

- プロジェクトまたはグループのオーナーロールを持つ管理者である必要があります。

コンプライアンス違反レポートを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **コンプライアンスセンター**を選択します。

コンプライアンス違反レポートには、以下が表示されます:

- **ステータス**: 違反の現在のステータス。たとえば、[レビューが必要]、[解決済み]、または[却下]などがあります。
- **違反の制御とフレームワーク**: 違反した特定のコンプライアンス制御と、それに関連付けられたフレームワーク。
- **監査イベント**: 違反をトリガーしたイベントに関する詳細。
- **プロジェクト**: 違反が発生したプロジェクト。
- **検出日**: 違反が特定された日時。
- **アクション**: 違反に関する詳細情報を表示するためのリンク。

レポートでは、次のことができます:

- 列ヘッダーを選択して、レポートをソートします。
- ステータスドロップダウンリストを使用して、違反のステータスを変更します。
- ページネーションを使用して、違反の複数のページをナビゲートします。
- 各違反に関する詳細情報を表示します。
- レポートをCSVファイルとしてエクスポートします。

## 違反の詳細 {#violation-details}

特定の違反に対して**詳細**を選択すると、以下を表示できます:

- 違反IDとステータス。
- 違反が発生した場所（プロジェクト）。
- 以下を含む包括的な監査イベント情報:
  - イベント作成者。
  - イベントターゲット。
  - イベントの詳細。
  - IPアドレス。
  - ターゲットタイプ。
- 以下を含む違反したコントロール情報:
  - コントロール名と説明。
  - 関連付けられたコンプライアンスフレームワーク。
  - 要件。
- 違反を解決するためのリンク付きの修正の提案。

## 違反ステータスの管理 {#manage-violation-statuses}

コンプライアンス違反のステータスを更新して、修正の進捗状況を追跡できます。使用可能なステータスは次のとおりです:

- **Needs Review**（レビューが必要）: 新しい違反のデフォルトのステータス
- **In Progress**（進行中）: 違反が対処されています
- **解決済み**: 違反は修正されました
- **やめる**: 違反はレビューされ、無視されました

違反ステータスを変更するには:

1. コンプライアンス違反レポートで、更新する違反を見つけます。
1. **ステータス**列の現在のステータスドロップダウンリストを選択します。
1. ドロップダウンリストメニューから新しいステータスを選択します。

ステータスがすぐに更新され、レポートに反映されます。

## コンプライアンス違反レポートをエクスポートする {#export-compliance-violations-report}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/551244)されました。

{{< /history >}}

グループ内のすべてのプロジェクトのコンプライアンス違反のCSVレポートをエクスポートします。エクスポートされたレポートには以下が含まれます:

- 検出日（現在の日時が最初）
- 違反ID
- ステータス
- フレームワーク
- コンプライアンス制御
- コンプライアンス要件
- 監査イベントの作成者
- 監査イベントタイプ
- 監査イベント名
- 監査イベントメッセージ
- プロジェクト:

レポート:

- メールの添付ファイルが大きくなりすぎないように、15MBに切り詰められます。
- Webインターフェースに適用された現在のフィルターに関係なく、すべての違反が含まれます。

前提要件: 

- グループの管理者であるか、オーナーロールを持っている必要があります。

コンプライアンス違反レポートをエクスポートするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **コンプライアンスセンター**を選択します。
1. 右上隅で、**エクスポート**を選択します。
1. **Export violations report**（違反レポートのエクスポート）を選択します。

レポートがコンパイルされ、添付ファイルとしてメールの受信トレイに配信されます。

## 静的コンプライアンス違反レポート {#static-compliance-violations-report}

{{< alert type="warning" >}}

このは、GitLab 18.2で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/551236)となり、18.8で削除される予定です。

{{< /alert >}}

静的コンプライアンス違反レポートは、グループ内のすべてのプロジェクトのマージリクエストアクティビティーの概要を提供します。

静的コンプライアンス違反レポートで行を選択すると、次の情報を提供するドロワーが表示されます:

- プロジェクト名と、プロジェクトに割り当てられている場合は[コンプライアンスフレームワークのラベル](../../project/working_with_projects.md#add-a-compliance-framework-to-a-project)。
- 違反を導入したマージリクエストへのリンク。
- 形式`[source] into [target]`のマージリクエストのブランチのパス。
- マージリクエストへの変更をコミットしたユーザーのリスト。
- マージリクエストにコメントしたユーザーのリスト。
- マージリクエストを承認したユーザーのリスト。
- マージリクエストをマージしたユーザー。

### 静的コンプライアンス違反レポートを表示します {#view-the-static-compliance-violations-report}

{{< history >}}

- ターゲットブランチ検索がGitLab 16.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/358414)。

{{< /history >}}

前提要件: 

- プロジェクトまたはグループのオーナーロールを持つ管理者である必要があります。

静的コンプライアンス違反レポートを置き換えるために、次のようにしました:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **コンプライアンスセンター**を選択します。

コンプライアンスレポートは、次のようにソートできます:

- 重大度レベル。
- 違反の種類。
- マージリクエストのタイトル。

コンプライアンス違反レポートは、次のようにフィルタリングできます:

- 違反が見つかったプロジェクト。
- 違反の日付範囲。
- 違反のターゲットブランチ。

行を選択して、コンプライアンス違反の詳細を表示します。

### 重大度レベル {#severity-levels}

各コンプライアンス違反には、次の重大度のいずれかがあります。

<!-- vale gitlab_base.SubstitutionWarning = NO -->

| アイコン                                  | 重大度レベル。 |
|:--------------------------------------|:---------------|
| {{< icon name="severity-critical" >}} | 重大       |
| {{< icon name="severity-high" >}}     | 高           |
| {{< icon name="severity-medium" >}}   | 中程度         |
| {{< icon name="severity-low" >}}      | 低            |
| {{< icon name="severity-info" >}}     | 情報           |

<!-- vale gitlab_base.SubstitutionWarning = YES -->

### 違反の種類 {#violation-types}

| 違反                         | 重大度レベル。 | カテゴリ                                      | 説明                                                                                                                                                                                                                                            |
|:----------------------------------|:---------------|:----------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 作成者がマージリクエストを承認しました     | 高           | [職務分離](#separation-of-duties) | マージリクエストの作成者が、自分のマージリクエストを承認しました。詳細については、[マージリクエスト作成者による承認を禁止する](../../project/merge_requests/approvals/settings.md#prevent-approval-by-merge-request-creator)を参照してください。                     |
| コミッターがマージリクエストを承認しました | 高           | [職務分離](#separation-of-duties) | マージリクエストのコントリビュートするコミッターが、コントリビュートするしたマージリクエストを承認しました。詳細については、[コミットを追加するユーザーによる承認を禁止する](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits)を参照してください。 |
| 2件未満の承認          | 高           | [職務分離](#separation-of-duties) | マージリクエストは、2件未満の承認でマージされました。詳細については、[マージリクエストの承認ルール](../../project/merge_requests/approvals/rules.md)を参照してください。                                                                                     |

#### 職務分離 {#separation-of-duties}

GitLabは、マージリクエストを作成および承認するユーザー間の職務分離ポリシーをサポートしています。職務分離の基準は次のとおりです:

- [マージリクエストの作成者は、自分のマージリクエストを承認できません](../../project/merge_requests/approvals/settings.md#prevent-approval-by-merge-request-creator)。
- [マージリクエストのコミッターは、コミットを追加したマージリクエストを承認できません](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits)。
- [マージリクエストをマージするために必要な最小承認数は、少なくとも2つです](../../project/merge_requests/approvals/rules.md)。

### グループ内のプロジェクトに関するマージリクエストコンプライアンス違反のレポートをエクスポートする {#export-a-report-of-merge-request-compliance-violations-on-projects-in-a-group}

{{< history >}}

- GitLab 16.4で`compliance_violation_csv_export`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/356791)されました。デフォルトでは無効になっています。
- GitLab 16.5の[GitLab.comおよびGitLab Self-Managedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/issues/424447)。
- GitLab 16.9で[`compliance_violation_csv_export`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142568)は削除されました。

{{< /history >}}

グループ内のプロジェクトに属するマージリクエストに関するマージリクエストコンプライアンス違反のレポートをエクスポートします。レポート:

- 違反レポートでフィルターを使用しないでください。
- メールの添付ファイルが大きくなりすぎないように、15MBに切り詰められます。

前提要件: 

- グループの管理者であるか、オーナーロールを持っている必要があります。

グループ内のプロジェクトのマージリクエストコンプライアンス違反のレポートをエクスポートするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **コンプライアンスセンター**を選択します。
1. 右上隅で、**エクスポート**を選択します。
1. **Export violations report**（違反レポートのエクスポート）を選択します。

レポートがコンパイルされ、添付ファイルとしてメールの受信トレイに配信されます。
