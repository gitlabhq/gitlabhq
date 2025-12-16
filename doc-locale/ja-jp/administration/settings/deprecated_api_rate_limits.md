---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabの非推奨APIに対する制限を定義します。
gitlab_dedicated: yes
title: 非推奨APIレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

非推奨のAPIエンドポイントは代替機能に置き換えられましたが、下位互換性を損なうことなく削除することはできません。ユーザーに代替機能へのスイッチを促すために、非推奨のエンドポイントに制限レート制限を設定します。

## 非推奨のAPIエンドポイント {#deprecated-api-endpoints}

このレート制限には、すべての非推奨APIエンドポイントが含まれているわけではなく、パフォーマンスに影響を与える可能性のあるものだけが含まれています:

- [`GET /groups/:id`](../../api/groups.md#get-a-single-group) `with_projects=0` クエリパラメータなし。

## 非推奨のAPIレート制限を定義します {#define-deprecated-api-rate-limits}

非推奨のAPIエンドポイントに対するレート制限は、デフォルトで無効になっています。有効にすると、非推奨のエンドポイントへのリクエストに対する一般的なユーザーおよびIPレート制限よりも優先されます。既存の一般的なユーザーおよびIPレート制限を維持し、非推奨のAPIエンドポイントのレート制限を増減できます。このオーバーライドによって提供される他の新機能はありません。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

非推奨のAPIエンドポイントへのリクエストに対する一般的なユーザーおよびIPレート制限をオーバーライドするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **Deprecated API Rate Limits**（非推奨のAPIレート制限）を展開します。
1. 有効にするレート制限の種類のチェックボックスを選択します:
   - **Unauthenticated API request rate limit**（認証されていないAPIリクエストのレート制限）
   - **Authenticated API request rate limit**（認証済みAPIリクエストのレート制限）
1. **unauthenticated**（認証されていない）を選択した場合:
   1. **Maximum unauthenticated API requests per period per IP**（IPごとの期間あたりの認証されていないAPIリクエストの最大数）を選択します。
   1. **認証されていないAPIレート制限期間 (秒単位)**を選択します。
1. **authenticated**（認証済み）を選択した場合:
   1. **Maximum authenticated API requests per period per user**（ユーザーごとの期間あたりの認証済みAPIリクエストの最大数）を選択します。
   1. **認証されたAPIレート制限期間(秒単位)**を選択します。

## 関連トピック {#related-topics}

- [レート制限](../../security/rate_limits.md)
- [ユーザーとIPのレート制限](user_and_ip_rate_limits.md)
