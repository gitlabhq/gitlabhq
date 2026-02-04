---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Terraformステートの設定
description: Terraformステートの暗号化とストレージ制限を設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[Terraformステートファイル](../terraform_state.md)の設定（暗号化やストレージ制限など）を構成できます。

## Terraformステートの暗号化 {#terraform-state-encryption}

{{< history >}}

- GitLab 18.8で[導入](https://gitlab.com/groups/gitlab-org/-/epics/19738)されました。

{{< /history >}}

デフォルトでは、GitLabはTerraformステートファイルを暗号化してから保存します。必要に応じて、暗号化をオフにできます。

暗号化をオフにすると、Terraformステートファイルは、暗号化されずに受信した状態で保存されます。

前提条件: 

- 管理者アクセス権が必要です。
- `skip_encrypting_terraform_state_file`機能フラグを有効にする必要があります。

Terraformステートの暗号化を設定するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Terraformステート**を展開します。
1. **Turn on Terraform state encryption**チェックボックスを選択またはクリアします。
1. **変更を保存**を選択します。

{{< alert type="warning" >}}

暗号化をオフにすると、変更は新しいTerraformステートファイルのみに適用されます。暗号化された既存のファイルは暗号化されたままとなり、期待どおりに動作し続けます。

{{< /alert >}}

## Terraformステートのストレージ制限 {#terraform-state-storage-limits}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352951)されました。

{{< /history >}}

[Terraformステートファイル](../terraform_state.md)の合計ストレージを制限できます。制限は、個々のステートファイルバージョンごとに適用され、新しいバージョンが作成されるときにチェックされます。

前提条件: 

- 管理者アクセス権が必要です。

ストレージ制限を追加するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Terraformステート**を展開します。
1. **Terraformステートのサイズ制限 (バイト)**フィールドに、サイズ制限をバイト単位で入力します。無制限サイズのファイルを許可するには、`0`に設定します。
1. **変更を保存**を選択します。

Terraformステートファイルがこの制限を超えると、GitLabはそれらを保存せず、関連するTerraform操作を拒否します。
