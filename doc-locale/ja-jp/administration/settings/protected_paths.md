---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: 保護されたパス
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

レート制限は、ウェブアプリケーションのセキュリティと耐久性を向上させる手法です。詳細については、[Rate limits](../../security/rate_limits.md)を参照してください。

指定されたパスをレート制限（保護）できます。これらのパスに対して、GitLabは、保護されたパスで、IPアドレスごとに1分あたり10リクエストを超えるPOSTリクエスト、およびIPアドレスごとに1分あたり10リクエストを超えるGETリクエストに対して、HTTPステータス`429`を返します。

たとえば、以下は1分あたり最大10リクエストに制限されています:

- ユーザーサインイン
- ユーザーサインアップ（有効な場合）
- ユーザーパスワードリセット

10件のリクエストの後、クライアントは60秒待ってから再試行する必要があります。

こちらも参照してください:

- [デフォルトで保護された](../instance_limits.md#by-protected-path)パスのリスト。
- [User and IP rate limits](user_and_ip_rate_limits.md#response-headers)は、ブロックされたリクエストに返されるヘッダー用です。

## 保護されたパスの設定 {#configure-protected-paths}

保護されたパスのスロットリングはデフォルトで有効になっており、無効化またはカスタマイズできます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **ネットワーク**を選択します。
1. **保護されたパス**を展開します。

レート制限を超えたリクエストは、`auth.log`に記録されます。
