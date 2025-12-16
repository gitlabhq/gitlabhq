---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Terraformの制限
description: Terraformストレージ制限を設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352951)されました。

{{< /history >}}

[TerraformのStateファイル](../terraform_state.md)の合計ストレージを制限できます。制限は個々のステートファイルバージョンに適用され、新しいバージョンが作成されるたびにチェックされます。

ストレージ制限を追加するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Terraformの制限**を展開します。
1. サイズ制限をバイト単位で入力します。無制限のサイズのファイルを許可するには、`0`に設定します。

TerraformのStateファイルがこの制限を超えると、保存されず、関連するTerraform操作は拒否されます。
