---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: グループでのプロジェクト作成をスピードアップするには、カスタムプロジェクトテンプレートをビルドし、グループで共有します。
title: グループのカスタムプロジェクトテンプレート
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトを作成するときは、[テンプレートのリストから選択](../project/_index.md)できます。これらのテンプレート（GitLab PagesやRubyなど）は、テンプレートに含まれるファイルのコピーを新しいプロジェクトに設定します。この情報は、[GitLabプロジェクトのインポート/エクスポート](../project/settings/import_export.md)で使用される情報と同じであり、新しいプロジェクトをより迅速に開始するのに役立ちます。

グループ内のすべてのプロジェクトが同じリストを持つように、利用可能なテンプレートの[リストをカスタマイズ](../project/_index.md)できます。これを行うには、テンプレートとして使用するプロジェクトをサブグループに入力します。

[インスタンスのカスタムテンプレート](../../administration/custom_project_templates.md)を設定することもできます。

## グループのプロジェクトテンプレートをセットアップする {#set-up-project-templates-for-a-group}

前提要件: 

- グループのオーナーロールを持っている必要があります。

グループにカスタムプロジェクトテンプレートを設定するには、プロジェクトテンプレートを含むサブグループをグループ設定に追加します。

1. グループで、[サブグループ](subgroups/_index.md)を作成します。
1. テンプレートとして、[新しいサブグループにプロジェクトを追加](_index.md#add-projects-to-a-group)します。
1. グループの左側のメニューで、**設定 > 一般**を選択します。
1. **カスタムプロジェクトテンプレート**を展開し、サブグループを選択します。

次にグループメンバーがプロジェクトを作成するときに、サブグループ内の任意のプロジェクトを選択できます。

ネストされたサブグループ内のプロジェクトは、テンプレートリストには含まれません。

## テンプレートとして使用できるプロジェクト {#which-projects-are-available-as-templates}

- パブリックプロジェクトと内部プロジェクトは、**GitLab Pages**と**セキュリティとコンプライアンス**を除くすべての[プロジェクト機能](../project/settings/_index.md#configure-project-features-and-permissions)が**アクセスできるすべてのユーザー**に設定されている場合、認証済みユーザー全員が新しいプロジェクトのテンプレートとして選択できます。
- プライベートプロジェクトは、プロジェクトのメンバーであるユーザーのみが選択できます。

[既知のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/480779)があります。[継承されたメンバー](../project/members/_index.md#membership-types)は、`project_templates_without_min_access`機能フラグが有効になっていない限り、プロジェクトテンプレートを選択できません。この機能フラグはGitLab.comでは[無効になっている](https://gitlab.com/gitlab-org/gitlab/-/issues/480779)ため、テンプレートプロジェクトへの直接のメンバーシップをユーザーに許可する必要があります。

## 構成例 {#example-structure}

`myorganization`のプロジェクトテンプレートのサンプルグループとプロジェクト構成を次に示します: 

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

## テンプレートからコピーされるもの {#what-is-copied-from-the-templates}

テンプレートからプロジェクトを作成すると、エクスポート可能なすべてのプロジェクトアイテムがテンプレートから新しいプロジェクトにコピーされます。これらのアイテムは次のとおりです: 

- リポジトリのブランチ、コミット、およびタグ。
- プロジェクトのアップロード。
- プロジェクト設定。
- イシューとマージリクエスト、それらのコメント、およびその他のメタデータ。
- ラベル、マイルストーン、スニペット、およびリリース。
- CI/CDパイプライン設定。

コピーされるものの完全なリストについては、[エクスポートされるプロジェクト項目](../project/settings/import_export.md#project-items-that-are-exported)を参照してください。

### 権限と機密データ {#permissions-and-sensitive-data}

コピーの動作は、権限によって異なる場合があります: 

- インスタンスのカスタムテンプレートを含むプロジェクトのオーナーロールを持っているか、GitLab管理者である場合、プロジェクトメンバーを含むすべてのプロジェクト設定が新しいプロジェクトにコピーされます。
- プロジェクトのオーナーロールがない場合、またはGitLab管理者でない場合、プロジェクトのデプロイキーとプロジェクトのWebhookには機密データが含まれているため、コピーされません。

## テンプレート内のユーザー割り当て {#user-assignments-in-templates}

別のユーザーが作成したテンプレートを使用すると、テンプレート内のユーザーに割り当てられた項目はすべて、自分に再割り当てされます。保護ブランチやタグなどのセキュリティ機能を設定する場合は、この再アサインを理解することが重要です。たとえば、テンプレートに保護ブランチが含まれている場合は次の通りです。

- テンプレートでは、ブランチはテンプレートのオーナーがデフォルトブランチにマージすることを許可しています。
- テンプレートから作成されたプロジェクトでは、ブランチはあなたがデフォルトブランチにマージすることを許可しています。

## トラブルシューティング {#troubleshooting}

### プロジェクトの作成時に、管理者がグループのカスタムプロジェクトテンプレートを表示できない {#administrator-cannot-see-custom-project-templates-for-the-group-when-creating-a-project}

グループのカスタムプロジェクトテンプレートは、グループメンバーのみが利用できます。使用している管理者アカウントがグループのメンバーでない場合、テンプレートにアクセスできません。
