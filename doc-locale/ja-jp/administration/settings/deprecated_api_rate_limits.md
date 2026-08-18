---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab上の非推奨APIの制限を定義します。
gitlab_dedicated: yes
title: 非推奨APIレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

非推奨APIエンドポイントは代替機能に置き換えられましたが、下位互換性を損なわずに削除することはできません。ユーザーに代替への切り替えを促すため、非推奨エンドポイントに制限的なレート制限を設定します。

## 非推奨のAPIエンドポイント {#deprecated-api-endpoints}

このレート制限は、すべての非推奨APIエンドポイントではなく、パフォーマンスに影響を与える可能性のあるもののみを含みます:

- [`GET /groups/:id`](../../api/groups.md#retrieve-a-group)（`with_projects=0`クエリパラメータなし）。

## 非推奨APIレート制限を定義する {#define-deprecated-api-rate-limits}

非推奨APIエンドポイントのレート制限は、デフォルトで無効になっています。これらを有効にすると、非推奨エンドポイントへのリクエストに対する一般的なユーザーおよびIPレート制限に優先します。すでに設定されている一般的なユーザーおよびIPレート制限を維持し、非推奨APIエンドポイントのレート制限を増減できます。この上書きによって、他の新機能は提供されません。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

非推奨APIエンドポイントへのリクエストに対する一般的なユーザーおよびIPレート制限を上書きするには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **ネットワーク**を選択します。
1. **Deprecated API Rate Limits**を展開する。
1. 有効にするレート制限の種類に対応するチェックボックスを選択します:
   - **Unauthenticated API request rate limit**
   - **Authenticated API request rate limit**
1. If you selected **unauthenticated**:
   1. **Maximum unauthenticated API requests per period per IP**を選択します。
   1. **認証されていないAPIレート制限期間 (秒単位)** を選択します。
1. If you selected **authenticated**:
   1. **Maximum authenticated API requests per period per user**を選択します。
   1. **認証されたAPIレート制限期間(秒単位)** を選択します。

## 関連トピック {#related-topics}

- [レート制限](../../security/rate_limits.md)
- [ユーザーおよびIPレート制限](user_and_ip_rate_limits.md)
