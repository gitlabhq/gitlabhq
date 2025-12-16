---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 組織APIのレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/470613)されたのは、GitLab 17.5で、`allow_organization_creation`という[フラグ](../feature_flags/_index.md)が使用されました。デフォルトでは無効になっています。これは[実験的機能](../../policy/development_stages_support.md)です。
- GitLab 18.4で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/549062)されました。機能フラグ`allow_organization_creation`は統合され、`organization_switching`に名前が変更されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

レート制限を超えたリクエストは、`auth.log`ファイルに記録されます。

たとえば、`POST /organizations`に400の制限を設定した場合、1分以内に400のレートを超えるAPIエンドポイントへのリクエストはブロックされます。エンドポイントへのアクセスは、1分後に復元されます。

[POST /organizations API](../../api/organizations.md#create-an-organization)へのリクエストについて、1分あたりのユーザーごとのレート制限を構成できます。デフォルトは10です。

## レート制限を変更する {#change-the-rate-limit}

レート制限を変更するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **ネットワーク**を選択します。
1. **組織APIレートの制限**を展開します。
1. 任意のレート制限の値を変更します。レート制限は、ユーザーごとに1分あたりの制限です。レート制限を無効にするには、値を`0`に設定します。
1. **変更を保存**を選択します。
