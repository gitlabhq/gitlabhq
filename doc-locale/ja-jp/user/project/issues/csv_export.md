---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CSVにイシューをエクスポート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `IID`、`Type`、`Start Date`、および`Parent IID`の列は、GitLab 18.4で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199945)されました。

{{< /history >}}

GitLabからイシューをプレーンテキストのCSV（[コンマ区切り値](https://en.wikipedia.org/wiki/Comma-separated_values)）ファイルにエクスポートできます。CSVファイルはメールに添付され、デフォルトの通知メールアドレスに送信されます。

<!-- vale gitlab_base.Spelling = NO -->

CSVファイルは、Microsoft Excel、OpenOffice Calc、Google Sheetsなどの、プロッターまたはスプレッドシートベースのプログラムで使用できます。CSV形式のイシューリストを使用して、以下を行います:

<!-- vale gitlab_base.Spelling = YES -->

- オフライン分析用のイシューのスナップショットを作成したり、GitLabにいない可能性のある他のチームと共有したりできます。
- CSVデータから図、グラフ、チャートを作成します。
- 監査または共有のために、データを他の形式に変換します。
- イシューをGitLab外のシステムにインポートします。
- 長期的な傾向を、長期にわたって作成された複数のスナップショットで分析します。
- 長期的なデータを使用して、イシューで提供された関連するフィードバックを収集し、実際のメトリクスに基づいて製品を改善します。

## イシューをエクスポートする {#select-issues-to-export}

イシューは個々のプロジェクトからエクスポートできますが、グループからはエクスポートできません。

前提要件: 

- 少なくともゲストの役割が必要です。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択します。
1. イシューのリストの上にある**結果を検索またはフィルタリング**を選択します。
1. 表示されるドロップダウンリストで、フィルタリングする属性を選択します。フィルターオプションの詳細については、[イシューのリストをフィルター](managing_issues.md#filter-the-list-of-issues)を参照してください。
1. 右上にある**アクション**（{{< icon name="ellipsis_v" >}}）> **CSV形式でエクスポート**を選択します。
1. ダイアログで、メールアドレスが正しいことを確認し、**イシューをエクスポート**を選択します。

一致するすべてのイシューがエクスポートされます。最初のページに表示されないイシューも含まれます。エクスポートされたCSVには、イシューからの添付ファイルは含まれていません。

## 形式 {#format}

CSVファイルの形式は次のとおりです:

- ソートはタイトル順です。
- 列はコンマで区切られています。
- 必要に応じて、フィールドは二重引用符（`"`）で囲まれます。
- 改行文字は行を区切ります。

{{< alert type="note" >}}

GitLabで表示したときにエクスポートされたファイルの表示に影響を与える可能性のあるCSV解析中の要件については、[CSV解析中の考慮事項](../repository/files/csv.md#csv-parsing-considerations)を参照してください。

{{< /alert >}}

## 列 {#columns}

次の列がCSVファイルに含まれています。

| 列            | 説明 |
| ----------------- | ----------- |
| ID                | イシュー`id`  |
| IID               | イシュー`iid` |
| タイトル             | イシュー`title` |
| 説明       | イシュー`description` |
| 型              | イシュー`type` |
| URL               | GitLab上のイシューへのリンク |
| ステート             | `Open`または`Closed` |
| 機密      | `Yes`または`No` |
| ロック済み            | `Yes`または`No` |
| マイルストーン         | イシューマイルストーンのタイトル |
| ラベル            | ラベル（コンマ区切り） |
| 作成者            | イシュー作成者の氏名 |
| 作成者のユーザー名   | `@`記号が省略された作成者のユーザー名 |
| 担当者          | イシューの担当者の氏名 |
| 担当者のユーザー名 | `@`記号が省略された担当者のユーザー名 |
| 作成日（UTC）  | `YYYY-MM-DD HH:MM:SS`の形式で表示されます。 |
| 更新日（UTC）  | `YYYY-MM-DD HH:MM:SS`の形式で表示されます。 |
| クローズ日（UTC）   | `YYYY-MM-DD HH:MM:SS`の形式で表示されます。 |
| イシューの期日          | `YYYY-MM-DD`の形式で表示されます。 |
| 開始日        | `YYYY-MM-DD`の形式で表示されます。 |
| 親ID         | 親のID |
| 親IID        | 親のIID |
| 親のタイトル      | 親のタイトル |
| 見積もり時間     | 秒単位の[見積もり時間](../time_tracking.md#estimates) |
| 経過時間        | 秒単位での[消費時間](../time_tracking.md#time-spent) |
| ウェイト            | イシューのイシューのウェイト |

## トラブルシューティング {#troubleshooting}

エクスポートされたイシューを操作する場合、次の問題が発生する可能性があります。

### エクスポートのサイズ {#size-of-export}

イシューはメールの添付ファイルとして送信されます。さまざまなメールプロバイダー全体で正常に配信できるように、エクスポートの制限は15 MBです。制限に達した場合は、エクスポートする前に検索範囲を絞り込んでください。たとえば、オープンなイシューとクローズされたイシューを別々にエクスポートすることを検討してください。
