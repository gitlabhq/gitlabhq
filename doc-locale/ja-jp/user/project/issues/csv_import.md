---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CSVからのイシューのインポート
description: "CSVファイルをアップロードして、イシューをプロジェクトにインポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.7のプランナーロールで[許可](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)が追加されました。
- GitLab 18.4で`type`列の[サポートが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199945)されました。

{{< /history >}}

次の列を含むCSV（カンマ区切り値）ファイルをアップロードして、イシューをプロジェクトにインポートできます:

| 名前          | 必須                             | 説明 |
| ------------- | ------------------------------------ | ----------- |
| `title`       | {{< icon name="check-circle" >}}対応 | イシューのタイトル。 |
| `description` | {{< icon name="check-circle" >}}対応 | イシューの説明。 |
| `due_date`    | {{< icon name="dotted-circle" >}}対象外 | `YYYY-MM-DD`形式のイシューの期日。 |
| `milestone`   | {{< icon name="dotted-circle" >}}対象外 | イシューのマイルストーンのタイトル。GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112204)されました。 |
| `type`        | {{< icon name="dotted-circle" >}}対象外 | イシューのタイプ。GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200893)されました。 |

他の列のデータはインポートされません。

`description`フィールドを使用して、[クイックアクション](../quick_actions.md)を埋め込み、他のデータをイシューに追加できます。たとえば、ラベル、アサイン、およびマイルストーンなどです。

または、[イシューを移動](managing_issues.md#move-an-issue)できます。イシューを移動すると、より多くのデータが保持されます。

CSVファイルをアップロードするユーザーは、インポートされたイシューの作成者として設定されます。

イシューをインポートするには、プロジェクトのプランナーロールまたは少なくともデベロッパーロールが必要です。

## インポートの準備 {#prepare-for-the-import}

- いくつかのイシューのみを含むテストファイルのインポートを検討してください。GitLab APIを使用せずに大規模なインポートを元に戻す方法はありません。
- CSVファイルが[ファイル形式](#csv-file-format)の要件を満たしていることを確認してください。
- CSVにマイルストーンヘッダーが含まれている場合は、ファイル内の一意のマイルストーンタイトルがすべて、プロジェクトまたはその親グループにすでに存在することを確認してください。

## ファイルをインポート {#import-the-file}

イシューをインポートするには:

1. プロジェクトの**イシュー**ページに移動します。
1. プロジェクトにイシューがあるかどうかに応じて、インポート機能を開きます:
   - プロジェクトに既存のイシューがある場合: 右上隅の**一括編集**の横にある**アクション**（{{< icon name="ellipsis_v" >}}）> **CSVからのインポート**を選択します。
   - プロジェクトにイシューがない場合：ページの中央にある**CSVからのインポート**を選択します。
1. インポートするファイルを選択し、**イシューのインポート**を選択します。

ファイルはバックグラウンドで処理され、エラーが検出された場合、またはインポートが完了すると、通知メールが送信されます。

## CSVファイル形式 {#csv-file-format}

イシューをインポートするには、GitLabでCSVファイルに特定の形式が必要です。

{{< alert type="note" >}}

GitLabで表示した場合にインポートされたファイルの表示方法に影響を与える可能性のあるCSV解析要件については、[CSV解析に関する考慮事項](../repository/files/csv.md#csv-parsing-considerations)を参照してください。

{{< /alert >}}

| 要素                | 形式 |
| ---------------------- | ------ |
| ヘッダー行             | CSVファイルには、次のヘッダーを含める必要があります：`title`および`description`。ヘッダーの大文字と小文字は区別されません。 |
| 列                | `title`、`description`、`due_date`、`milestone`、`type`以外の列のデータはインポートされません。 |
| 区切り文字             | 列の区切り文字は、ヘッダー行から検出されます。サポートされている区切り文字は、カンマ（`,`）、セミコロン（`;`）、およびタブ（`\t`）です。行の区切り文字は、`CRLF`または`LF`のいずれかです。 |
| 二重引用符 | 二重引用符（`"`）文字は、フィールドを引用符で囲むために使用され、フィールドで列の区切り文字を使用できるようになります（以下のサンプルCSVデータの3行目を参照）。引用符で囲まれたフィールドに二重引用符（`"`）を挿入するには、2つの二重引用符文字を連続して使用します（`""`）。 |
| データ行              | ヘッダー行の後、後続の行は同じ列の順序を使用する必要があります。イシューのタイトルは必須ですが、説明はオプションです。 |

フィールドに特殊文字（たとえば、`,`または`\n`）または複数行がある場合（たとえば、[クイックアクション](../quick_actions.md)を使用する場合）、文字を二重引用符（`"`）で囲みます。

[クイックアクション](../quick_actions.md)を使用する場合も同様です:

- 各アクションは別の行にある必要があります。
- `/label`や`/milestone`のようなクイックアクションの場合、ラベルまたはマイルストーンがプロジェクトにすでに存在する必要があります。
- イシューを割り当てるユーザーは、プロジェクトのメンバーである必要があります。

CSVデータのサンプル:

```plaintext
title,description,due_date,milestone
My Issue Title,My Issue Description,2022-06-28
Another Title,"A description, with a comma",
"One More Title","One More Description",
An Issue with Quick Actions,"Hey can we change the frontend?

/assign @sjones
/label ~frontend ~documentation",
An issue with milestone,"My milestone is created",,v1.0
```

### ファイルサイズ {#file-size}

制限は、GitLabインスタンスのホスト方法によって異なります:

- GitLab Self-Managed: GitLabインスタンスの`Max Attachment Size`の設定値によって設定されます。
- GitLab SaaS: GitLab.comでは、10MBに設定されています。
