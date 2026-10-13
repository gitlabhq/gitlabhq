---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabの非推奨APIの制限を定義します。
gitlab_dedicated: yes
title: 非推奨APIレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

非推奨のAPIエンドポイントは代替機能に置き換えられましたが、後方互換性を損なわずに削除することはできません。代替に切り替えるようユーザーに促すため、非推奨のエンドポイントに制限的なレート制限を設定します。

## 非推奨のAPIエンドポイント {#deprecated-api-endpoints}

このレート制限には、すべての非推奨APIエンドポイントは含まれません。パフォーマンスに影響を与える可能性のあるもののみが含まれます:

- [`GET /groups/:id`](../../api/groups.md#retrieve-a-group)に`with_projects=0`クエリパラメータがない場合。

## 非推奨APIレート制限を定義する {#define-deprecated-api-rate-limits}

非推奨APIエンドポイントのレート制限は、デフォルトで無効になっています。有効にすると、非推奨のエンドポイントへのリクエストに対する一般的なユーザーおよびIPレート制限を上書きします。既存の一般的なユーザーおよびIPレート制限を維持し、非推奨APIエンドポイントのレート制限を増減できます。このオーバーライドによって、その他の新機能は提供されません。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

非推奨APIエンドポイントへのリクエストに対する一般的なユーザーおよびIPレート制限を上書きするには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **非推奨のAPIレート制限**を展開します。
1. 有効にするレート制限の種類に対応するチェックボックスをオンにします:
   - **認証されていないAPIリクエストレート制限**
   - **認証されたAPIリクエストレート制限**
1. **認証されていない**を選択した場合:
   1. **IPごとの期間あたりの未認証APIリクエストの最大数**を選択します。
   1. **認証されていないAPIレート制限期間（秒単位）**を選択します。
1. **認証した**を選択した場合:
   1. **IPごとの期間あたりの認証済みAPIリクエストの最大数**を選択します。
   1. **認証されたAPIレート制限期間（秒単位）** を選択します。

## 関連トピック {#related-topics}

- [レート制限](../_index.md)
- [ユーザーとIPのレート制限](../../administration/settings/user_and_ip_rate_limits.md)
