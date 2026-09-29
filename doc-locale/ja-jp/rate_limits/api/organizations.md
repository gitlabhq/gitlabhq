---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 組織APIレートの制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 17.5で`allow_organization_creation`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/470613)されました。デフォルトでは無効になっています。これは[実験的機能](../../policy/development_stages_support.md)です。
- GitLab 18.4で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/549062)されました。機能フラグ`allow_organization_creation`は統合され、`organization_switching`に名前が変更されました。
- GitLab 19.4で機能フラグが`org_stage_experimental`に[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249678)されました。デフォルトでは無効になっています。機能フラグ`organization_switching`は削除されました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

レート制限を超過したリクエストは、`auth.log`ファイルにログが記録されます。

例えば、`POST /organizations`に400の制限を設定した場合、1分以内に400を超えるAPIエンドポイントへのリクエストはブロックされます。エンドポイントへのアクセスは1分後に復元されます。

[POST /organizations API](../../api/organizations.md#create-an-organization)へのリクエストに対して、ユーザーごとの1分あたりのレート制限を構成できます。デフォルトは10です。

## レート制限を変更する {#change-the-rate-limit}

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **組織APIレートの制限**を展開します。
1. 任意のレート制限の値を変更します。レート制限は、ユーザーごとに1分あたりで設定されます。レート制限を無効にするには、値を`0`に設定します。
1. **変更を保存**を選択します。
