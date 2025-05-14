---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: To speed up project creation in your group, build custom project templates and share them with your group.
title: カスタムグループレベルのプロジェクトテンプレート
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトを作成するときは、[テンプレートのリストから選択](../project/_index.md)できます。これらのテンプレート（GitLab PagesやRubyなど）は、テンプレートに含まれるファイルのコピーを新しいプロジェクトに設定します。この情報は、[GitLabプロジェクトのインポート/エクスポート](../project/settings/import_export.md)で使用される情報と同じであり、新しいプロジェクトをより迅速に開始するのに役立ちます。

グループ内のすべてのプロジェクトが同じリストを持つように、利用可能なテンプレートの[リストをカスタマイズ](../project/_index.md)できます。これを行うには、テンプレートとして使用するプロジェクトをサブグループに入力します。

[インスタンスのカスタムテンプレート](../../administration/custom_project_templates.md)を設定することもできます。

## グループのプロジェクトテンプレートを設定する

前提要件:

- グループのオーナーのロールを持っている必要があります。

グループにカスタムプロジェクトテンプレートを設定するには、プロジェクトテンプレートを含むサブグループをグループ設定に追加します。

1. グループで、[サブグループ](subgroups/_index.md)を作成します。
1. テンプレートとして、[新しいサブグループにプロジェクトを追加](_index.md#add-projects-to-a-group)します。
1. グループの左側のメニューで、**設定 > 一般**を選択します。
1. **カスタムプロジェクトテンプレート**を展開し、サブグループを選択します。

次にグループメンバーがプロジェクトを作成するときに、サブグループ内の任意のプロジェクトを選択できます。

ネストされたサブグループ内のプロジェクトは、テンプレートリストには含まれません。

## テンプレートして使用できるプロジェクト

- パブリックプロジェクトと内部プロジェクトは、**GitLab Pages**と**セキュリティとコンプライアンス**を除くすべての[プロジェクト機能](../project/settings/_index.md#configure-project-features-and-permissions)が**アクセスできるすべてのユーザー**に設定されている場合、認証済みユーザー全員が新しいプロジェクトのテンプレートとして選択できます。
- プライベートプロジェクトは、プロジェクトのメンバーであるユーザーのみが選択できます。

[既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/480779)があります。[継承されたメンバー](../project/members/_index.md#membership-types)は、`project_templates_without_min_access` 機能フラグが有効になっていない限り、プロジェクトテンプレートを選択できません。この機能フラグはGitLab.comでは[無効になっている](https://gitlab.com/gitlab-org/gitlab/-/issues/425452)ため、テンプレートプロジェクトの直接のメンバーシップをユーザーに許可する必要があります。

## 構成例

`myorganization`のプロジェクトテンプレートのサンプルグループとプロジェクトの構成を次に示します。

```plaintext
# GitLab instance and group
gitlab.com/myorganization/
    # Subgroups
    internal
    tools
    # Subgroup for handling project templates
    websites
        templates
            # Project templates
            client-site-django
            client-site-gatsby
            client-site-html

        # Other projects
        client-site-a
        client-site-b
        client-site-c
        ...
```

## テンプレートからコピーされるもの

インスタンス用に設定されたカスタムプロジェクトテンプレートリポジトリ全体がコピーされます。これには以下が含まれます。

- ブランチ
- コミット
- タグ

ユーザーの場合、次の通りです。

- インスタンスのカスタムテンプレートを含むプロジェクトのオーナーのロールを持っているか、GitLab管理者である場合、プロジェクトメンバーを含むすべてのプロジェクト設定が新しいプロジェクトにコピーされます。
- オーナーロールを持っていないか、GitLab管理者でない場合、プロジェクトのデプロイキーとプロジェクトのWebhookには機密データが含まれているため、コピーされません。

移行される項目の詳細については、[エクスポートされる項目](../project/settings/import_export.md#project-items-that-are-exported)を参照してください。

## テンプレート内のユーザー割り当て

別のユーザーが作成したテンプレートを使用すると、テンプレート内のユーザーに割り当てられた項目はすべて、自分に再割り当てされます。保護されたブランチやタグなどのセキュリティ機能を設定する場合は、この再割り当てを理解することが重要です。たとえば、テンプレートに保護ブランチが含まれている場合は次の通りです。

- テンプレートでは、ブランチは_テンプレートのオーナー_がデフォルトブランチにマージすることを許可しています。
- テンプレートから作成されたプロジェクトでは、ブランチは_あなた_がデフォルトブランチにマージすることを許可しています。

## トラブルシューティング

### プロジェクトの作成時に、管理者がグループのカスタムプロジェクトテンプレートを表示できない

グループのカスタムプロジェクトテンプレートは、グループメンバーのみが利用できます。使用している管理者アカウントがグループのメンバーでない場合、テンプレートにアクセスできません。
