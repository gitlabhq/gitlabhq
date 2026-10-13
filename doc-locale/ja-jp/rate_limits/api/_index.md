---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 特定のGitLab APIエンドポイントにレート制限を設定します。
title: APIレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ほとんどのAPIリクエストは、[一般的なユーザーおよびIPレート制限](../../administration/settings/user_and_ip_rate_limits.md)に対してカウントされます。一部のAPIでは、代わりに個別のレート制限を設定できます。APIレート制限は、そのAPIへのリクエストに対する一般的な制限よりも優先されます。一般的な制限を変更することなく、単一のAPIの制限を上げたり下げたりできます。他の動作に変更はありません。

これらの制限を設定するには、**管理者**エリアに移動し、**設定** > **ネットワーク**を選択します。

## 利用可能なAPIレート制限 {#available-api-rate-limits}

| API | 説明 |
|:----|:------------|
| [監査イベントAPI](../../administration/settings/rate-limit-on-audit-events-api.md) | インスタンス監査イベントを取得するリクエストを制限します。 |
| [非推奨のエンドポイント](deprecated.md) | 後方互換性を損なわずに削除できないが、代替があるエンドポイントを制限します。 |
| [グループAPI](groups.md) | グループを一覧表示、取得する、作成、アーカイブするリクエスト、およびグループメンバーを一覧表示、削除するリクエストを制限します。 |
| [組織API](organizations.md) | 組織を作成するリクエストを制限します。 |
| [パッケージレジストリ](package-registry.md) | パッケージAPIへのリクエストを制限します。これは、ダウンストリームプロジェクトが依存関係を解決するために呼び出すものです。 |
| [プロジェクトAPI](projects.md) | プロジェクトを一覧表示、取得する、作成するリクエスト、およびプロジェクトメンバーを一覧表示、削除するリクエストを制限します。 |
| [リポジトリファイルAPI](repository-files.md) | リポジトリ内のファイルをフェッチする、作成する、更新する、削除するリクエストを制限します。 |
| [ユーザーAPI](users.md) | ユーザーのフォロワー、ステータス、SSHキー、およびGPGキーを読み取るリクエストを制限します。 |

## 関連トピック {#related-topics}

- [レート制限](../_index.md)
- [設定不可能なレート制限](../non_configurable.md)
- [REST API](../../api/rest/_index.md)
