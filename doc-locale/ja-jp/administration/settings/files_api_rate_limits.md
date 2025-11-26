---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: リポジトリファイルAPIのレート制限を設定します。
title: リポジトリファイルAPIのレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Repository files API](../../api/repository_files.md)を使用すると、リポジトリ内のファイルをフェッチ、作成、更新、削除できます。Webアプリケーションのセキュリティと耐久性を向上させるために、このAPIで[レート制限](../../security/rate_limits.md)を適用できます。ファイルAPIに対して作成するレート制限は、[一般的なユーザーとIPのレート制限](user_and_ip_rate_limits.md)をオーバーライドします。

## ファイルAPIのレート制限を定義する {#define-files-api-rate-limits}

ファイルAPIのレート制限は、デフォルトで無効になっています。有効にすると、[Repository files API](../../api/repository_files.md)へのリクエストに対する一般的なユーザーとIPのレート制限よりも優先されます。すでに設定されている一般的なユーザーとIPのレート制限を維持し、ファイルAPIのレート制限を増減させることができます。このオーバーライドによって提供される新しい機能はありません。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

Repository files APIへのリクエストに対する一般的なユーザーとIPのレート制限をオーバーライドするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **Files API Rate Limits**（ファイルAPIのレート制限）を展開します。
1. 有効にするレート制限の種類のチェックボックスを選択します:
   - **Unauthenticated API request rate limit**（認証されていないAPIリクエストのレート制限）
   - **Authenticated API request rate limit**（認証されたAPIリクエストのレート制限）
1. **unauthenticated**（認証されていません）を選択した場合:
   1. **Max unauthenticated API requests per period per IP**（IPごとの期間あたりの最大未認証APIリクエスト数）を選択します。
   1. **認証されていないAPIレート制限期間 (秒単位)**を選択します。
1. **authenticated**（認証済み）を選択した場合:
   1. **Max authenticated API requests per period per user**（ユーザーごとの期間あたりの認証されたAPIリクエストの最大数）を選択します。
   1. **認証されたAPIレート制限期間(秒単位)**を選択します。

## 関連トピック {#related-topics}

- [レート制限](../../security/rate_limits.md)
- [リポジトリファイルAPI](../../api/repository_files.md)
- [ユーザーとIPのレート制限](user_and_ip_rate_limits.md)
