---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 監査イベントの管理
description: CSVエンコードとユーザー代理などを含む、GitLabインスタンスの監査イベントを表示、エクスポート、管理します。
---

[監査イベント](../../user/compliance/audit_events.md)に加えて、管理者として、追加機能にアクセスできます。

## インスタンス監査イベント {#instance-audit-events}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabインスタンス全体のユーザーアクションから監査イベントを表示できます。インスタンスの監査イベントを表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**モニタリング** > **監査イベント**を選択します。
1. 以下でフィルターします:
   - アクションを実行したプロジェクトのメンバー（ユーザー）
   - グループ
   - プロジェクト
   - 日付範囲

インスタンスの監査イベントは、[インスタンスの監査イベントAPI](../../api/audit_events.md#instance-audit-events)を使用してもアクセスできます。

## 監査イベントをエクスポートする {#exporting-audit-events}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- `Gitlab::Audit::InstanceScope`エンティティタイプは、GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418185)されたインスタンス監査イベント用です。

{{< /history >}}

インスタンスの監査イベントの現在の表示（フィルターを含む）をCSV（カンマ区切り値）ファイルとしてエクスポートできます。インスタンスの監査イベントをCSVにエクスポートするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**モニタリング** > **監査イベント**を選択します。
1. 利用可能な検索フィルターを選択します。
1. **CSV形式でエクスポート**を選択します。

ダウンロード確認ダイアログが表示され、CSVファイルをダウンロードできます。エクスポートされたCSVは、最大100000件のイベントに制限されています。この制限に達すると、残りのレコードは切り詰められます。

### 監査イベントのCSVエンコード {#audit-event-csv-encoding}

エクスポートされたCSVファイルは、次のようにエンコードされます:

- `,`は、列の区切り文字として使用されます
- `"`は、必要に応じてフィールドを引用するために使用されます。
- `\n`は、行を区切るために使用されます。

最初の行にはヘッダーが含まれており、次の表に値の説明とともにリストされています:

| 列                | 説明                                                                        |
| --------------------- | ---------------------------------------------------------------------------------- |
| **ID**                | 監査イベント`id`                                                                  |
| **作成者ID**         | 作成者のID。                                                                  |
| **作成者の名前**       | 作成者のフルネーム。                                                           |
| **エンティティID**         | スコープのID。                                                                   |
| **エンティティタイプ**       | スコープのタイプ（`Project`、`Group`、`User`、または`Gitlab::Audit::InstanceScope`）。 |
| **エンティティパス**      | スコープのパス。                                                                 |
| **ターゲットID**         | ターゲットのID。                                                                  |
| **ターゲットタイプ**       | ターゲットのタイプ。                                                                |
| **ターゲット詳細**    | ターゲットの詳細。                                                             |
| **アクション**            | アクションの説明。                                                         |
| **IPアドレス**        | アクションを実行した作成者のIPアドレス。                                 |
| **作成日（UTC）**  | `YYYY-MM-DD HH:MM:SS`としてフォーマットされます。                                                |

すべての項目は、昇順で`created_at`でソートされます。

## ユーザーの代理 {#user-impersonation}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ユーザーが[代理](../admin_area.md#user-impersonation)されると、そのアクションは、次の追加の詳細とともに監査イベントとしてログに記録されます:

- 監査イベントには、代理を行う管理者に関する情報が含まれます。
- 管理者の代理セッションの開始と終了に対して、追加の監査イベントが記録されます。

![ユーザーが代理された監査イベント。](img/impersonated_audit_events_v15_7.png)

## タイムゾーン {#time-zones}

タイムゾーンと監査イベントの詳細については、[タイムゾーン](../../user/compliance/audit_events.md#time-zones)を参照してください。

## 監査イベントにコントリビュートする {#contribute-to-audit-events}

監査イベントへのコントリビュートについては、[監査イベントへのコントリビュート](../../user/compliance/audit_events.md#contribute-to-audit-events)を参照してください。
