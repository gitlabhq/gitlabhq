---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 監査イベントの管理
description: GitLabインスタンスの監査イベントを表示、エクスポートする、および管理します。CSVエンコードとユーザー代理を含みます。
---

[監査イベント](../../user/compliance/audit_events.md)に加えて、管理者は追加機能にアクセスできます。

## インスタンス監査イベント {#instance-audit-events}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabインスタンス全体でのユーザーアクションからの監査イベントを表示できます。インスタンス監査イベントを表示するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. 以下でフィルターします:
   - アクションを実行したプロジェクトのメンバー（ユーザー）
   - グループ
   - プロジェクト
   - 日付範囲

インスタンス監査イベントは、[インスタンス監査イベントAPI](../../api/audit_events.md#instance-audit-events)を使用してもアクセスできます。

## 監査イベントのエクスポート {#exporting-audit-events}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.2で[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/418185)インスタンス監査イベントのエンティティタイプ`Gitlab::Audit::InstanceScope`。

{{< /history >}}

インスタンス監査イベントの現在のビュー（フィルターを含む）をCSV（カンマ区切り値）ファイルとしてエクスポートすることができます。インスタンス監査イベントをCSVにエクスポートするには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. 利用可能な検索フィルターを選択します。
1. **CSVとしてエクスポート**を選択します。

その後、CSVファイルをダウンロードするための確認ダイアログが表示されます。エクスポートされたCSVは最大100000イベントに制限されます。この制限に達すると、残りのレコードは切り捨てられます。

### 監査イベントCSVエンコード {#audit-event-csv-encoding}

エクスポートされたCSVファイルは次のようにエンコードされます:

- `,`は列区切り文字として使用されます。
- 必要に応じて、`"`はフィールドを引用符で囲むために使用されます。
- `\n`は行を区切るために使用されます。

最初の行には、ヘッダーが含まれており、次の表に値の説明とともにリストされています:

| 列                | 説明                                                                        |
| --------------------- | ---------------------------------------------------------------------------------- |
| **ID**                | 監査イベント`id`。                                                                  |
| **作成者ID**         | 作成者のID。                                                                  |
| **Author Name**       | 作成者のフルネーム。                                                           |
| **エンティティID**         | スコープのID。                                                                   |
| **Entity Type**       | スコープのタイプ（`Project`、`Group`、`User`、または`Gitlab::Audit::InstanceScope`）。 |
| **Entity Path**       | スコープのパス。                                                                 |
| **ターゲットID**         | ターゲットのID。                                                                  |
| **ターゲットタイプ**       | ターゲットのタイプ。                                                                |
| **Target Details**    | ターゲットの詳細。                                                             |
| **アクション**            | アクションの説明。                                                         |
| **IPアドレス**        | アクションを実行した作成者のIPアドレス。                                 |
| **Created At (UTC)**  | `YYYY-MM-DD HH:MM:SS`の形式で表示されます。                                                |

すべての項目は、`created_at`で昇順にソートされます。

## ユーザーの代理 {#user-impersonation}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ユーザーが[代理される](../admin_area.md#user-impersonation)と、そのアクションは次の追加詳細とともに監査イベントとして記録されます:

- 監査イベントには、代理する管理者に関する情報が含まれます。
- 管理者の代理セッションの開始と終了について、追加の監査イベントが記録されます。

![ユーザーが代理された監査イベント。](img/impersonated_audit_events_v15_7.png)

## タイムゾーン {#time-zones}

タイムゾーンと監査イベントの詳細については、[タイムゾーン](../../user/compliance/audit_events.md#time-zones)を参照してください。

## 監査イベントにコントリビュートする {#contribute-to-audit-events}

監査イベントへのコントリビュートに関する情報については、[監査イベントにコントリビュートする](../../user/compliance/audit_events.md#contribute-to-audit-events)を参照してください。
