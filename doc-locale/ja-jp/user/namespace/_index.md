---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ネームスペース
description: さまざまな種類のネームスペースについて説明します。
---

ネームスペースは、GitLabでプロジェクトを整理します。各ネームスペースは分離されているため、複数のネームスペースで同じプロジェクト名を使用できます。

ネームスペースの名前を選択する際は、次の点に注意してください:

- [命名規則](../reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs)
- [予約済みグループ名](../reserved_names.md#reserved-group-names)

{{< alert type="note" >}}

ネームスペースにピリオド（`.`）が含まれている場合、[Terraformモジュールを公開する](../packages/terraform_module_registry/_index.md#publish-a-terraform-module)際に、SSL証明書の検証やソースパスに関する問題が発生します。

{{< /alert >}}

## ネームスペースの種類 {#types-of-namespaces}

GitLabには、次の2種類のネームスペースがあります:

- **ユーザー**: 個人のネームスペースにはユーザー名に基づいて名前が付けられます。個人のネームスペースの条件は次のとおりです:
  - サブグループは作成できません。
  - 所属するグループは、個人のネームスペースの権限や機能を継承しません。
  - 作成するすべてのプロジェクトは、このネームスペースのスコープの対象となります。
  - ユーザー名を変更すると、プロジェクトとネームスペースのURLも変更されます。ユーザー名を変更する前に、[リポジトリのリダイレクト](../project/repository/_index.md#repository-path-changes)について確認してください。

- **グループ**: グループまたはサブグループのネームスペースは、グループ名またはサブグループ名に基づいて名前が付けられます。グループおよびサブグループのネームスペースの条件は次のとおりです:
  - 複数のサブグループを作成して、複数のプロジェクトを管理できます。
  - サブグループは、親グループの設定の一部を継承します。これらは、サブグループの**設定**で確認できます。
  - 各サブグループと各プロジェクトに専用の設定を指定できます。
  - 名前と関係なく、グループまたはサブグループのURLを管理できます。

## 自分がいるネームスペースの種類を確認する {#determine-which-type-of-namespace-youre-in}

グループのネームスペースにいるのか、個人のネームスペースにいるのかを確認するには、URLを表示します。次に例を示します:

| ネームスペースの対象 | URL | ネームスペース |
| ------------- | --- | --------- |
| `alex`という名前のユーザー | `https://gitlab.example.com/alex` | `alex` |
| `alex-team`という名前のグループ | `https://gitlab.example.com/alex-team` | `alex-team` |
| `alex-team`という名前のグループと、`marketing`という名前のサブグループ |  `https://gitlab.example.com/alex-team/marketing` | `alex-team/marketing` |
