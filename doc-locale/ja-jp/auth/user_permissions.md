---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザー権限
description: ユーザーの種類、ロール、権限、メンバーシップ、カスタムロール、およびアクセス制御。
---

GitLabでは、プロジェクトとグループ内で何ができるかを制御するために、ユーザーの種類、ロール、およびメンバーシップを組み合わせた包括的な権限システムを使用します。ユーザーには、プロジェクトとグループにおける権限を定義するロールが割り当てられます。メンバーシップとそれに関連付けられた権限は、トップレベルグループからサブグループとそのプロジェクトにカスケードされます。

ユーザーの種類には、標準的な権限を持つ一般ユーザーから、システムを完全に制御できる管理者まで、GitLabインスタンス全体でさまざまなレベルのアクセス権があります。ユーザーは、組織のニーズに合わせて調整された特定の権限を持つカスタムロールを持つこともできます。

## ユーザーの種類 {#user-types}

{{< cards >}}

- [監査担当者ユーザー](../administration/auditor_users.md)
- [外部ユーザー](../administration/external_users.md)
- [内部ユーザー](../administration/internal_users.md)
- [エンタープライズユーザー](../user/enterprise_user/_index.md)
- [サービスアカウント](../user/profile/service_accounts.md)

{{< /cards >}}

## ロールと権限 {#roles-and-permissions}

{{< cards >}}

- [ロールと権限](../user/permissions.md)
- [ゲストロール](../administration/guest_users.md)
- [カスタムロール](../user/custom_roles/_index.md)
- [カスタム権限](../user/custom_roles/abilities.md)

{{< /cards >}}
