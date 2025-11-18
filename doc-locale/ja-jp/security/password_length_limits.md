---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: カスタムパスワード長の制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

デフォルトでは、GitLabは次の長さのパスワードをサポートしています:

- 最小: 8文字
- 最大: 128文字

変更できるのは、パスワードの最小の長さのみです。最小の長さを変更しても、既存のユーザーパスワードには影響しません。既存のユーザーは、新しい制限に従うためにパスワードのリセットを求められません。新しい制限は、新規ユーザーのサインアップ時、および既存のユーザーがパスワードのリセットを実行したときにのみ適用されます。

## パスワードの最小長の変更 {#modify-minimum-password-length}

ユーザーパスワードの長さは、デフォルトで最小8文字に設定されています。

GitLab UIを使用してパスワードの最小長を変更するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **新規登録の制限**を展開する。
1. **Minimum password length**（パスワードの最小長）に`8`以上の値を入力します。
1. **変更を保存**を選択します。
