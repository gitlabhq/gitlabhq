---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: リポジトリファイルAPIのレート制限を設定します。
title: リポジトリファイルAPIのレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[リポジトリファイルAPI](../../api/repository_files.md)を使用すると、リポジトリ内のファイルをフェッチ、作成、更新、削除できます。ウェブアプリケーションのセキュリティと耐久性を向上させるため、このAPIに対して[レート制限](../_index.md)を適用できます。ファイルAPI用に作成したレート制限は、[一般的なユーザーとIPのレート制限](../../administration/settings/user_and_ip_rate_limits.md)を上書きします。

## ファイルAPIのレート制限を定義する {#define-files-api-rate-limits}

ファイルAPIのレート制限は、デフォルトで無効になっています。有効にすると、[リポジトリファイルAPI](../../api/repository_files.md)へのリクエストに対する一般的なユーザーとIPのレート制限を上書きします。既存の一般的なユーザーおよびIPのレート制限を維持し、ファイルAPIのレート制限を増減できます。このオーバーライドによって、その他の新機能は提供されません。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

リポジトリファイルAPIへのリクエストに対する一般的なユーザーとIPのレート制限を上書きするには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **ファイルAPIレート制限**を展開します。
1. 有効にするレート制限の種類に対応するチェックボックスをオンにします:
   - **認証されていないAPIリクエストレート制限**
   - **認証されたAPIリクエストレート制限**
1. **認証されていない**を選択した場合:
   1. **IPごとの期間あたりの最大未認証APIリクエスト数**を選択します。
   1. **認証されていないAPIレート制限期間（秒単位）** を選択します。
1. **認証した**を選択した場合:
   1. **ユーザーごとの期間あたりの最大認証済みAPIリクエスト数**を選択します。
   1. **認証されたAPIレート制限期間（秒単位）** を選択します。

## 関連トピック {#related-topics}

- [レート制限](../_index.md)
- [リポジトリファイルAPI](../../api/repository_files.md)
- [ユーザーとIPのレート制限](../../administration/settings/user_and_ip_rate_limits.md)
